import Foundation
import SQLite3

struct HistoryEntry: Identifiable, Equatable {
    let id: String
    let createdAt: Date
    let provider: LLMProvider
    let model: String
    let input: String
    let spoken: String
    let formal: String
    let domains: [Domain]
    let jargonLevel: Int
    let voiceStyle: VoiceStyle
}

final class HistoryStore: @unchecked Sendable {
    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "thought2english.history.sqlite")

    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init() {
        queue.sync {
            do {
                try open()
                try createTablesIfNeeded()
            } catch {
                // Best-effort. App remains usable without history.
            }
        }
    }

    func add(_ entry: HistoryEntry) {
        queue.async {
            do {
                try self.open()
                try self.insert(entry)
            } catch {
                // ignore
            }
        }
    }

    func list(limit: Int, completion: @escaping @Sendable ([HistoryEntry]) -> Void) {
        queue.async {
            let entries = (try? self.fetchList(limit: limit)) ?? []
            DispatchQueue.main.async { completion(entries) }
        }
    }

    func search(query: String, limit: Int, completion: @escaping @Sendable ([HistoryEntry]) -> Void) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        queue.async {
            let entries = (try? self.fetchSearch(query: trimmed, limit: limit)) ?? []
            DispatchQueue.main.async { completion(entries) }
        }
    }

    func delete(id: String, completion: (@Sendable () -> Void)? = nil) {
        queue.async {
            do {
                try self.open()
                try self.deleteById(id: id)
            } catch {
                // ignore
            }
            if let completion {
                DispatchQueue.main.async { completion() }
            }
        }
    }

    // MARK: - SQLite

    private func open() throws {
        if db != nil { return }

        let url = try historyDatabaseURL()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if sqlite3_open(url.path, &db) != SQLITE_OK {
            throw HistoryError.sqliteOpenFailed
        }
        sqlite3_busy_timeout(db, 2000)
    }

    private func createTablesIfNeeded() throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS entries (
          id TEXT PRIMARY KEY,
          created_at REAL NOT NULL,
          provider TEXT NOT NULL,
          model TEXT NOT NULL,
          input TEXT NOT NULL,
          spoken TEXT NOT NULL,
          formal TEXT NOT NULL,
          domains TEXT NOT NULL,
          jargon_level INTEGER NOT NULL,
          voice_style TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_entries_created_at ON entries(created_at DESC);
        """
        try exec(sql)
    }

    private func insert(_ entry: HistoryEntry) throws {
        let sql = """
        INSERT OR REPLACE INTO entries
          (id, created_at, provider, model, input, spoken, formal, domains, jargon_level, voice_style)
        VALUES
          (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.sqlitePrepareFailed
        }

        sqlite3_bind_text(stmt, 1, entry.id, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 2, entry.createdAt.timeIntervalSince1970)
        sqlite3_bind_text(stmt, 3, entry.provider.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 4, entry.model, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 5, entry.input, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 6, entry.spoken, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 7, entry.formal, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 8, entry.domains.map(\.rawValue).joined(separator: ","), -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 9, Int32(entry.jargonLevel))
        sqlite3_bind_text(stmt, 10, entry.voiceStyle.rawValue, -1, SQLITE_TRANSIENT)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw HistoryError.sqliteStepFailed
        }
    }

    private func fetchList(limit: Int) throws -> [HistoryEntry] {
        try open()
        let sql = """
        SELECT id, created_at, provider, model, input, spoken, formal, domains, jargon_level, voice_style
        FROM entries
        ORDER BY created_at DESC
        LIMIT ?;
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.sqlitePrepareFailed
        }
        sqlite3_bind_int(stmt, 1, Int32(max(1, limit)))

        return try readRows(stmt: stmt)
    }

    private func fetchSearch(query: String, limit: Int) throws -> [HistoryEntry] {
        try open()
        let sql = """
        SELECT id, created_at, provider, model, input, spoken, formal, domains, jargon_level, voice_style
        FROM entries
        WHERE input LIKE ? OR spoken LIKE ? OR formal LIKE ?
        ORDER BY created_at DESC
        LIMIT ?;
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.sqlitePrepareFailed
        }

        let pattern = "%\(query)%"
        sqlite3_bind_text(stmt, 1, pattern, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, pattern, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, pattern, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 4, Int32(max(1, limit)))

        return try readRows(stmt: stmt)
    }

    private func deleteById(id: String) throws {
        try open()
        let sql = "DELETE FROM entries WHERE id = ?;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryError.sqlitePrepareFailed
        }
        sqlite3_bind_text(stmt, 1, id, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw HistoryError.sqliteStepFailed
        }
    }

    private func readRows(stmt: OpaquePointer?) throws -> [HistoryEntry] {
        var results: [HistoryEntry] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard
                let id = columnText(stmt, index: 0),
                let providerRaw = columnText(stmt, index: 2),
                let model = columnText(stmt, index: 3),
                let input = columnText(stmt, index: 4),
                let spoken = columnText(stmt, index: 5),
                let formal = columnText(stmt, index: 6),
                let domainsRaw = columnText(stmt, index: 7),
                let voiceRaw = columnText(stmt, index: 9)
            else { continue }

            let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 1))
            let provider = LLMProvider(rawValue: providerRaw) ?? .gemini
            let jargonLevel = Int(sqlite3_column_int(stmt, 8))
            let voiceStyle = VoiceStyle(rawValue: voiceRaw) ?? .tradfi
            let domains = domainsRaw.split(separator: ",").compactMap { Domain(rawValue: String($0)) }

            results.append(HistoryEntry(
                id: id,
                createdAt: createdAt,
                provider: provider,
                model: model,
                input: input,
                spoken: spoken,
                formal: formal,
                domains: domains,
                jargonLevel: jargonLevel,
                voiceStyle: voiceStyle
            ))
        }
        return results
    }

    private func exec(_ sql: String) throws {
        var err: UnsafeMutablePointer<Int8>?
        defer { sqlite3_free(err) }
        guard sqlite3_exec(db, sql, nil, nil, &err) == SQLITE_OK else {
            throw HistoryError.sqliteExecFailed
        }
    }

    private func columnText(_ stmt: OpaquePointer?, index: Int32) -> String? {
        guard let cString = sqlite3_column_text(stmt, index) else { return nil }
        return String(cString: cString)
    }

    private func historyDatabaseURL() throws -> URL {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let newDir = appSupport.appending(path: "Thought2English", directoryHint: .isDirectory)
        let newURL = newDir.appending(path: "history.sqlite", directoryHint: .notDirectory)

        // Migrate from the old folder name if present.
        let oldDir = appSupport.appending(path: "Englearn", directoryHint: .isDirectory)
        let oldURL = oldDir.appending(path: "history.sqlite", directoryHint: .notDirectory)

        if FileManager.default.fileExists(atPath: oldURL.path),
           !FileManager.default.fileExists(atPath: newURL.path)
        {
            do {
                try FileManager.default.createDirectory(at: newDir, withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: oldURL, to: newURL)
            } catch {
                // Best-effort migration. If it fails, continue using the new location.
            }
        }

        return newURL
    }
}

enum HistoryError: Error {
    case sqliteOpenFailed
    case sqlitePrepareFailed
    case sqliteStepFailed
    case sqliteExecFailed
}
