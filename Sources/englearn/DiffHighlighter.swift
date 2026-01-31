import Foundation
import AppKit
import SwiftUI

enum DiffHighlighter {
    static func highlightInsertions(original: String, revised: String) -> AttributedString {
        let originalWords = tokenizeWords(original)
        let revisedWords = tokenizeWords(revised)

        let diff = revisedWords.difference(from: originalWords)
        let insertedOffsets = Set(diff.compactMap { change -> Int? in
            switch change {
            case .insert(let offset, _, _): return offset
            case .remove: return nil
            }
        })

        let joined = revisedWords.joined(separator: " ")
        let mutable = NSMutableAttributedString(string: joined)

        var searchLocation = 0
        for (index, word) in revisedWords.enumerated() {
            let ns = joined as NSString
            let remaining = NSRange(location: searchLocation, length: max(0, ns.length - searchLocation))
            let range = ns.range(of: word, options: [], range: remaining)
            if range.location != NSNotFound {
                if insertedOffsets.contains(index) {
                    mutable.addAttribute(
                        .backgroundColor,
                        value: NSColor.systemYellow.withAlphaComponent(0.35),
                        range: range
                    )
                }
                searchLocation = range.location + range.length
            }
        }

        return AttributedString(mutable)
    }

    private static func tokenizeWords(_ text: String) -> [String] {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
    }
}
