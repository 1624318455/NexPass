import AuthenticationServices
import UIKit

/// iOS Credential Provider Extension for NexPass.
///
/// ## Autofill Flow
/// 1. Safari requests credentials for a domain → `prepareInterfaceToProvideCredentials`
/// 2. We search the shared `CredentialStore` index for matching entries
/// 3. User selects an entry → `fillCredential` reads the password from `PasswordCache`
/// 4. We return an `ASPasswordCredential` to the system
///
/// ## Password Availability
/// - Passwords are cached by the main app when the vault is unlocked.
/// - Cache entries expire after 5 minutes (TTL).
/// - If no cached password is found, we show a prompt telling the user
///   to open NexPass and unlock the vault first.
class CredentialProviderViewController: ASCredentialProviderViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        PasswordCache.purgeExpired()
        NSLog("[CredentialProvider] Extension loaded")
    }

    // MARK: - Credential Presentation

    override func prepareInterfaceToProvideCredentials(
        for serviceIdentifiers: [ASCredentialServiceIdentifier]
    ) {
        let domain = serviceIdentifiers.first?.identifier ?? ""
        NSLog("[CredentialProvider] Requesting credentials for: \(domain)")

        let matches = CredentialStore.search(query: domain)

        if matches.isEmpty {
            showEmptyState(for: domain)
            return
        }

        showCredentialList(matches, for: domain)
    }

    override func prepareInterfaceForExtensionConfiguration() {
        NSLog("[CredentialProvider] Extension configuration opened")
    }

    // MARK: - Credential Selection

    private func showCredentialList(_ entries: [CredentialEntry], for domain: String) {
        let listView = CredentialListView(entries: entries) { [weak self] selected in
            self?.fillCredential(selected)
        }

        let hostingController = UIHostingController(rootView: listView)
        hostingController.view.frame = self.view.bounds
        self.addChild(hostingController)
        self.view.addSubview(hostingController.view)
    }

    private func showEmptyState(for domain: String) {
        let emptyView = EmptyStateView(domain: domain)

        let hostingController = UIHostingController(rootView: emptyView)
        hostingController.view.frame = self.view.bounds
        self.addChild(hostingController)
        self.view.addSubview(hostingController.view)
    }

    private func showPasswordUnavailable(for entry: CredentialEntry) {
        let view = PasswordUnavailableView(entryName: entry.name)

        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = self.view.bounds
        self.addChild(hostingController)
        self.view.addSubview(hostingController.view)
    }

    // MARK: - Credential Fill

    /// Fills the selected credential back to the system.
    ///
    /// Attempts to load the decrypted password from `PasswordCache`.
    /// If the cache is empty (vault locked or expired), shows a prompt
    /// asking the user to open NexPass first.
    private func fillCredential(_ entry: CredentialEntry) {
        // Try to load password from the shared cache
        if let cachedPassword = PasswordCache.loadPassword(forUUID: entry.id) {
            NSLog("[CredentialProvider] Filling credential with cached password: \(entry.name)")

            let credential = ASPasswordCredential(
                user: entry.username,
                password: cachedPassword
            )
            self.extensionContext.completeRequest(
                withSelectedCredential: credential,
                completionHandler: nil
            )
        } else {
            // Password not cached — vault may be locked
            NSLog("[CredentialProvider] No cached password for: \(entry.name)")
            showPasswordUnavailable(for: entry)
        }
    }
}

// MARK: - SwiftUI Views

import SwiftUI

struct CredentialListView: View {
    let entries: [CredentialEntry]
    let onSelect: (CredentialEntry) -> Void

    var body: some View {
        NavigationView {
            List(entries) { entry in
                Button(action: { onSelect(entry) }) {
                    HStack(spacing: 12) {
                        Image(systemName: entry.itemType == 1
                            ? "person.fill"
                            : "creditcard.fill")
                            .foregroundColor(.teal)
                            .frame(width: 32, height: 32)
                            .background(Color.teal.opacity(0.15))
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name)
                                .font(.system(.body, weight: .semibold))
                                .foregroundColor(.primary)

                            Text(entry.username)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("NexPass")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct EmptyStateView: View {
    let domain: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundColor(.teal)

            Text("No credentials found")
                .font(.headline)
                .foregroundColor(.primary)

            Text("No NexPass credentials match \"\(domain)\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

struct PasswordUnavailableView: View {
    let entryName: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundColor(.orange)

            Text("Vault Locked")
                .font(.headline)
                .foregroundColor(.primary)

            Text("To fill \"\(entryName)\", please open NexPass and unlock your vault first.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Passwords are cached for 5 minutes after unlock.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
