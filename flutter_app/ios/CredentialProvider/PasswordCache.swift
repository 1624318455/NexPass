import Foundation

/// Temporary password cache shared between the main NexPass app and the
/// CredentialProvider extension via an App Group container.
///
/// ## Security Model
/// - Decrypted passwords are stored **only** while the vault is unlocked.
/// - The main app calls `savePasswords()` when the vault is unlocked and
///   `clear()` when the vault is locked or the app enters background.
/// - The cache file resides in the App Group container, which is sandboxed
///   by iOS and inaccessible to third-party apps.
/// - Future upgrade: encrypt the cache with a Keychain-shared AES key.
///
/// ## Lifecycle
/// 1. User unlocks vault → main app calls `savePasswords(credentials)`
/// 2. Extension receives autofill request → reads via `loadPassword(forUUID:)`
/// 3. User locks vault / app backgrounded → main app calls `clear()`
struct PasswordCache {

    static let appGroupID = "group.io.nexpass.app"
    static let cacheFileName = "nexpass_password_cache.json"

    /// Cache entry containing the decrypted password.
    struct CacheEntry: Codable {
        let uuid: String
        let username: String
        let password: String
        let updatedAt: Date

        /// Auto-expire entries older than this duration.
        static let ttl: TimeInterval = 5 * 60 // 5 minutes
    }

    // MARK: - Write (Main App)

    /// Saves decrypted credentials to the shared cache.
    /// Called by the main app whenever the vault is unlocked or updated.
    static func savePasswords(_ credentials: [(uuid: String, username: String, password: String)]) {
        guard let containerURL = sharedContainerURL() else {
            NSLog("[PasswordCache] App Group container unavailable")
            return
        }

        let entries = credentials.map {
            CacheEntry(uuid: $0.uuid, username: $0.username, password: $0.password, updatedAt: Date())
        }

        let fileURL = containerURL.appendingPathComponent(cacheFileName)

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entries)
            try data.write(to: fileURL, options: .atomic)
            NSLog("[PasswordCache] Cached \(entries.count) passwords")
        } catch {
            NSLog("[PasswordCache] Failed to write cache: \(error)")
        }
    }

    // MARK: - Read (Extension)

    /// Loads a decrypted password for a specific credential UUID.
    /// Returns `nil` if the credential is not in cache or has expired.
    static func loadPassword(forUUID uuid: String) -> String? {
        guard let entries = loadEntries() else { return nil }
        let match = entries.first { $0.uuid == uuid }

        guard let entry = match else {
            NSLog("[PasswordCache] No cached password for UUID: \(uuid)")
            return nil
        }

        // Check TTL
        if Date().timeIntervalSince(entry.updatedAt) > CacheEntry.ttl {
            NSLog("[PasswordCache] Cached password expired for UUID: \(uuid)")
            return nil
        }

        return entry.password
    }

    /// Loads the full username for a credential UUID (for display).
    static func loadUsername(forUUID uuid: String) -> String? {
        guard let entries = loadEntries() else { return nil }
        return entries.first { $0.uuid == uuid }?.username
    }

    // MARK: - Clear (Main App)

    /// Clears all cached passwords.
    /// MUST be called when the vault is locked or the app enters background.
    static func clear() {
        guard let containerURL = sharedContainerURL() else { return }

        let fileURL = containerURL.appendingPathComponent(cacheFileName)

        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                NSLog("[PasswordCache] Cache cleared")
            }
        } catch {
            NSLog("[PasswordCache] Failed to clear cache: \(error)")
        }
    }

    /// Purges expired entries (housekeeping).
    static func purgeExpired() {
        guard let entries = loadEntries() else { return }
        let now = Date()
        let valid = entries.filter { now.timeIntervalSince($0.updatedAt) <= CacheEntry.ttl }

        if valid.count < entries.count {
            // Re-write with only valid entries
            guard let containerURL = sharedContainerURL() else { return }
            let fileURL = containerURL.appendingPathComponent(cacheFileName)
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(valid)
                try data.write(to: fileURL, options: .atomic)
                NSLog("[PasswordCache] Purged \(entries.count - valid.count) expired entries")
            } catch {
                NSLog("[PasswordCache] Failed to purge: \(error)")
            }
        }
    }

    /// Returns `true` if the cache has any (non-expired) entries.
    static var hasCachedPasswords: Bool {
        guard let entries = loadEntries() else { return false }
        let now = Date()
        return entries.contains { now.timeIntervalSince($0.updatedAt) <= CacheEntry.ttl }
    }

    // MARK: - Internal

    private static func loadEntries() -> [CacheEntry]? {
        guard let containerURL = sharedContainerURL() else { return nil }
        let fileURL = containerURL.appendingPathComponent(cacheFileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([CacheEntry].self, from: data)
        } catch {
            NSLog("[PasswordCache] Failed to decode cache: \(error)")
            return nil
        }
    }

    private static func sharedContainerURL() -> URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        )
    }
}
