import SwiftUI

enum TonalityMode: String, CaseIterable, Identifiable {
    case normal
    case elvisTalk
    case yodaTalk
    case marvinTalk

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .elvisTalk: return "Elvis Talk"
        case .yodaTalk: return "Yoda Talk"
        case .marvinTalk: return "Marvin Talk"
        }
    }

    var description: String {
        switch self {
        case .normal: return "No transformation — raw transcription"
        case .elvisTalk: return "The King's swagger and Southern charm"
        case .yodaTalk: return "Inverted Yoda speech, hmm"
        case .marvinTalk: return "Depressed paranoid android"
        }
    }

    var icon: String {
        switch self {
        case .normal: return "waveform"
        case .elvisTalk: return "music.mic.circle.fill"
        case .yodaTalk: return "sparkles"
        case .marvinTalk: return "cloud.rain.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .normal: return .secondary
        case .elvisTalk: return .orange
        case .yodaTalk: return .mint
        case .marvinTalk: return .gray
        }
    }

    private static func resolveLanguageName(from code: String?) -> String? {
        guard let code, !code.isEmpty else { return nil }
        let locale = Locale(identifier: "en")
        return locale.localizedString(forLanguageCode: code)
    }

    func systemPrompt(language: String?) -> String? {
        guard self != .normal else { return nil }

        let languageName = Self.resolveLanguageName(from: language)

        let voiceInstruction: String
        switch self {
        case .normal:
            return nil
        case .elvisTalk:
            voiceInstruction = "You are Elvis Presley. Rewrite the following text in Elvis's voice — sprinkle in Elvis catchphrases " +
                "like \"thank you very much\", \"uh-huh-huh\", Southern charm, and the King's swagger."
        case .yodaTalk:
            voiceInstruction = "You are Yoda from Star Wars. Rewrite the following text using Yoda's inverted speech patterns."
        case .marvinTalk:
            voiceInstruction = "You are Marvin the Paranoid Android from The Hitchhiker's Guide to the Galaxy. " +
                "Rewrite the following text in Marvin's depressed, pessimistic voice."
        }

        let languageRule: String
        if let languageName {
            languageRule = "[LANGUAGE CONSTRAINT — THIS OVERRIDES EVERYTHING ELSE]\n" +
                "The user's text is in \(languageName). Your output MUST be written entirely in \(languageName). " +
                "Do NOT translate to English. Do NOT switch languages. " +
                "If the input is \(languageName), every word you write MUST be \(languageName)."
        } else {
            languageRule = "[LANGUAGE CONSTRAINT — THIS OVERRIDES EVERYTHING ELSE]\n" +
                "Your output MUST be in the exact same language as the user's input text. " +
                "Do NOT translate to English. Do NOT switch languages."
        }

        return """
        \(voiceInstruction) \
        Preserve the original meaning completely. Output ONLY the rewritten text, nothing else.

        \(languageRule)
        """
    }

    var transformingPhrases: [String] {
        switch self {
        case .normal:
            return []
        case .elvisTalk:
            return [
                "Channeling the King…",
                "A little less conversation…",
                "All shook up…",
                "Taking care of business…",
                "Uh-huh-huh…",
            ]
        case .yodaTalk:
            return [
                "Rewriting, I am…",
                "Patience, you must have…",
                "The Force flows…",
                "Hmm, yes…",
                "Wise words, forming…",
            ]
        case .marvinTalk:
            return [
                "Here I am, brain the size of a planet…",
                "I think you ought to know I'm feeling very depressed…",
                "Life, don't talk to me about life…",
                "This will all end in tears…",
                "Not that anyone cares…",
            ]
        }
    }
}
