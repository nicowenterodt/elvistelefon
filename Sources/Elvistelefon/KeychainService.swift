import Foundation

enum KeychainService {
    private static let fileName = "api-key"

    private static var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Elvistelefon", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            // Owner-only permissions on the directory
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o700], ofItemAtPath: dir.path
            )
        }
        return dir.appendingPathComponent(fileName)
    }

    static func saveAPIKey(_ key: String) throws {
        let data = key.data(using: .utf8)!
        try data.write(to: storageURL, options: [.atomic, .completeFileProtection])
        // Owner read/write only
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600], ofItemAtPath: storageURL.path
        )
    }

    static func loadAPIKey() -> String? {
        guard let data = try? Data(contentsOf: storageURL) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteAPIKey() throws {
        if FileManager.default.fileExists(atPath: storageURL.path) {
            try FileManager.default.removeItem(at: storageURL)
        }
    }

    static var hasAPIKey: Bool {
        loadAPIKey() != nil
    }

    /// Migrates API key from the old "WhisperTranscribe" directory to the new "Elvistelefon" directory.
    static func migrateFromOldName() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let oldDir = appSupport.appendingPathComponent("WhisperTranscribe", isDirectory: true)
        let oldFile = oldDir.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: oldFile.path) else { return }
        guard let data = try? Data(contentsOf: oldFile),
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else { return }

        // Only migrate if we don't already have a key
        guard !hasAPIKey else {
            // Clean up old directory since we already have a key
            try? FileManager.default.removeItem(at: oldDir)
            return
        }

        try? saveAPIKey(key)
        try? FileManager.default.removeItem(at: oldDir)
    }
}
