import AuthenticationServices
import UIKit

/// iOS Credential Provider Extension for NexPass.
///
/// Implements `ASCredentialProviderViewController` to supply credentials
/// from the NexPass vault to Safari and system autofill.
///
/// ## Flow
/// 1. Safari requests credentials for a domain → [prepareInterfaceToProvideCredentials].
/// 2. We search the shared [CredentialStore] index for matching entries.
/// 3. We present a list; the user selects one.
/// 4. We return an `ASPasswordCredential` to the system.
///
/// ## Security
/// - The shared index contains only names/usernames — never passwords.
/// - When the user taps "Fill", we invoke the main app via a custom URL
///   scheme (`nexpass://fill/<uuid>`) to perform decryption and injection
///   in the main app's secure sandbox.
class CredentialProviderViewController: ASCredentialProviderViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("[CredentialProvider] Extension loaded")
    }

    // MARK: - Credential Presentation

    override func prepareInterfaceToProvideCredentials(
        for serviceIdentifiers: [ASCredentialServiceIdentifier]
    ) {
        let domain = serviceIdentifiers.first?.identifier ?? ""
        NSLog("[CredentialProvider] Requesting credentials for: \(domain)")

        // Search the shared vault index
        let matches = CredentialStore.search(query: domain)

        if matches.isEmpty {
            // No matching credentials — show empty state
            showEmptyState(for: domain)
            return
        }

        // Present a credential selection UI
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
        let emptyView = VStack(spacing: 12) {
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

        let hostingController = UIHostingController(rootView: emptyView)
        hostingController.view.frame = self.view.bounds
        self.addChild(hostingController)
        self.view.addSubview(hostingController.view)
    }

    /// Fills the selected credential back to the system.
    ///
    /// In production, this would invoke the main app via URL scheme to
    /// decrypt the password. For the stub, we return only the username.
    private func fillCredential(_ entry: CredentialEntry) {
        let credential = ASPasswordCredential(
            user: entry.username,
            password: "" // Main app decryption required for real password
        )

        // Log the fill attempt for analytics
        NSLog("[CredentialProvider] Filling credential: \(entry.name) (\(entry.username))")

        self.extensionContext.completeRequest(
            withSelectedCredential: credential,
            completionHandler: nil
        )
    }
}

// MARK: - SwiftUI List View (for credential selection)

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
