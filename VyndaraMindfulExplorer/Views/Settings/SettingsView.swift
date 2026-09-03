import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    NavigationLink {
                        StatsView()
                    } label: {
                        HStack {
                            Image(systemName: "chart.bar.xaxis").foregroundColor(AppTheme.accent)
                            Text("Statistics").font(.headline).foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.secondary)
                        }
                        .padding(14)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                        .shadow(color: AppTheme.primary.opacity(0.2), radius: 6, y: 3)
                    }
                    .frame(minHeight: 44)
                    Toggle(isOn: Binding(
                        get: { store.remindersEnabled },
                        set: { store.setRemindersEnabled($0) }
                    )) {
                        HStack {
                            Image(systemName: "bell.fill").foregroundColor(AppTheme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daily capture reminder").font(.headline).foregroundColor(.white)
                                Text("8:00 PM — don’t skip the streak").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .tint(AppTheme.accent)
                    .padding(14)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                    .shadow(color: AppTheme.primary.opacity(0.2), radius: 6, y: 3)
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
                .padding(18)
            }
            .screenBackdrop("BgDesk")
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .alert("Clear prompts and scenes?", isPresented: $confirmReset) {
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
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: AppTheme.primary.opacity(0.2), radius: 6, y: 3)
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
