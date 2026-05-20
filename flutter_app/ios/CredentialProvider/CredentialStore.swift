import Foundation

/// Provides read access to the NexPass vault via an App Group shared container.
///
/// The main app writes an encrypted JSON index of credentials to the shared
/// container. The credential provider extension reads this index to present
/// matching entries to Safari / system autofill without needing the full
/// Isar database engine.
///
/// ## Security model
/// - The shared JSON only contains **opaque UUIDs, names, and usernames** —
///   never plaintext passwords.
/// - When the user selects a credential, the extension invokes the main app
///   (via a URL scheme or `openURL`) to perform the actual decryption and
///   injection, keeping the master key inside the main app's sandbox.
struct CredentialStore {

    /// The App Group identifier — must match the value in both the main app
    /// and extension entitlements.
    static let appGroupID = "group.io.nexpass.app"

    /// File name for the shared credential index inside the App Group container.
    static let indexFileName = "vault_index.json"

    // MARK: - Read

    /// Loads the credential index from the shared container.
    static func loadIndex() -> [CredentialEntry] {
        guard let containerURL = sharedContainerURL() else {
            NSLog("[CredentialStore] App Group container unavailable")
            return []
        }

        let fileURL = containerURL.appendingPathComponent(indexFileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            NSLog("[CredentialStore] No vault index found at \(fileURL.path)")
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let entries = try JSONDecoder().decode([CredentialEntry].self, from: data)
            return entries
        } catch {
            NSLog("[CredentialStore] Failed to decode index: \(error)")
            return []
        }
    }

    /// Searches the index for entries matching a domain or query string.
    static func search(query: String) -> [CredentialEntry] {
        let lowerQuery = query.lowercased()
        return loadIndex().filter { entry in
            entry.name.lowercased().contains(lowerQuery) ||
            entry.username.lowercased().contains(lowerQuery) ||
            entry.matchDomains.contains { $0.lowercased().contains(lowerQuery) }
        }
    }

    // MARK: - Write (called by the main app)

    /// Writes a fresh credential index to the shared container.
    /// Called by the main app whenever the vault is updated.
    static func saveIndex(_ entries: [CredentialEntry]) {
        guard let containerURL = sharedContainerURL() else {
            NSLog("[CredentialStore] App Group container unavailable for write")
            return
        }

        let fileURL = containerURL.appendingPathComponent(indexFileName)

        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL, options: .atomic)
            NSLog("[CredentialStore] Index saved: \(entries.count) entries")
        } catch {
            NSLog("[CredentialStore] Failed to save index: \(error)")
        }
    }

    // MARK: - Helpers

    private static func sharedContainerURL() -> URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        )
    }
}

// MARK: - Credential Entry Model

/// Lightweight credential index entry shared between the main app and the
/// credential provider extension. Contains NO sensitive data.
struct CredentialEntry: Codable, Identifiable {
    /// UUID matching the Isar NexItem.uuid
    let id: String // uuid

    /// Display name (e.g. "GitHub Repository Keypair")
    let name: String

    /// Primary username / email
    let username: String

    /// Optional list of domains this credential applies to
    let matchDomains: [String]

    /// Item type (1 = Login, 2 = Card, etc.)
    let itemType: Int

    /// ISO-8601 timestamp of last update
    let updatedAt: String
}
