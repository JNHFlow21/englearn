import AVFoundation
import Foundation

enum SpeechTarget: String, Equatable {
    case spoken
    case formal
}

final class SpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    @Published private(set) var isSpeaking: Bool = false
    @Published private(set) var currentTarget: SpeechTarget?

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    @MainActor
    func toggleSpeak(target: SpeechTarget, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if isSpeaking, currentTarget == target {
            stop()
            return
        }

        stop()
        speak(target: target, text: trimmed)
    }

    @MainActor
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        currentTarget = nil
    }

    @MainActor
    private func speak(target: SpeechTarget, text: String) {
        currentTarget = target
        isSpeaking = true

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US") ?? AVSpeechSynthesisVoice()
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.05
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentTarget = nil
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentTarget = nil
        }
    }
}
