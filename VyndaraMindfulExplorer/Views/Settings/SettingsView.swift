import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear
                ScrollView {
                    VStack(spacing: 12) {
                        Toggle(isOn: Binding(
                            get: { store.remindersEnabled },
                            set: { store.setRemindersEnabled($0) }
                        )) {
                            HStack {
                                Image(systemName: "bell.fill").foregroundColor(AppTheme.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Evening pairing").font(.headline).foregroundColor(.white)
                                    Text("8:00 PM — two frames, one scene").font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                        .tint(AppTheme.accent)
                        .padding(14)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .frame(minHeight: 44)

                        row("Rate Us", "star.fill") { rateApp() }
                        row("Privacy", "hand.raised.fill") {
                            if let url = URL(string: AppLinks.privacy.rawValue) {
                                UIApplication.shared.open(url)
                            }
                        }
                        row("Terms", "doc.text.fill") {
                            if let url = URL(string: AppLinks.terms.rawValue) {
                                UIApplication.shared.open(url)
                            }
                        }
                        Button("Reset All Data", role: .destructive) { confirmReset = true }
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
                .clearScrollBackground()
            }
            .screenBackdrop()
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .alert("Clear pairings and scene cards?", isPresented: $confirmReset) {
                Button("Reset", role: .destructive) { store.resetAllData() }
                Button("Cancel", role: .cancel) { }
            }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
    }

    private func row(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundColor(AppTheme.accent)
                Text(title).font(.headline).foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }
            .padding(14)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(FilmPressStyle())
        .frame(minHeight: 44)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
