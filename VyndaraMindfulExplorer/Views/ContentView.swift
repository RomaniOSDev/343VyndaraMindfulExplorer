import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared
    @State private var showSettings = false
    @State private var showForm = false
    @State private var sprintCard: SceneCard?
    @State private var query = ""
    @State private var themeFilter: String?
    @State private var iconFilter: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Chronicle")
                        .font(.custom("Georgia", size: 34, relativeTo: .largeTitle))
                        .foregroundColor(.white)
                    Text("Prompts live on pictures. Pictures become scenes.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    streakRow

                    if let last = store.lastViewedCard {
                        NavigationLink(value: last) {
                            navRow("Continue: \(last.title)", icon: "arrow.uturn.backward.circle")
                        }
                    }

                    if let daily = store.dailyScene {
                        dailyCard(daily)
                    }

                    NavigationLink {
                        PhotoPromptsView()
                    } label: {
                        PolaroidFrame(tilt: -2) {
                            Image("BannerCamera")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 140)
                                .clipped()
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())

                    favoritesShelf

                    NavigationLink {
                        InspirationPreviewView()
                    } label: {
                        navRow("Explore scenes", icon: "magnifyingglass.circle")
                    }

                    NavigationLink {
                        CompareScenesView()
                    } label: {
                        navRow("Compare two scenes", icon: "rectangle.split.2x1")
                    }

                    NavigationLink {
                        StatsView()
                    } label: {
                        navRow("Studio statistics", icon: "chart.bar.xaxis")
                    }

                    chronicleFilters

                    if filteredEntries.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 36))
                                .foregroundColor(AppTheme.primary)
                            Text(store.entries.isEmpty ? "Start capturing inspirations!" : "No annotations match.")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(value: entry) {
                                HStack(alignment: .top) {
                                    Text(emoji(entry.icon))
                                        .font(.largeTitle)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.title)
                                            .font(.custom("Georgia", size: 20))
                                            .foregroundColor(.white)
                                        Text(entry.prompts.first ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                        Text(entry.theme)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.accent)
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(AppTheme.surface.opacity(0.85), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                    }

                    NeonButton(title: "New annotation", icon: "plus") { showForm = true }
                }
                .padding(18)
            }
            .screenBackdrop("BgDesk")
            .dismissKeyboardOnTap()
            .searchable(text: $query, prompt: "Search chronicle")
            .navigationDestination(for: ChronicleEntry.self) { entry in
                EntryDetailView(entryId: entry.id)
            }
            .navigationDestination(for: SceneCard.self) { card in
                PhotoPromptDetailView(card: card)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .sheet(isPresented: $showForm) { EntryFormView().environmentObject(store) }
            .sheet(isPresented: $showSettings) { SettingsView().environmentObject(store) }
            .fullScreenCover(item: $sprintCard) { card in
                SprintView(card: card).environmentObject(store)
            }
            .onAppear { store.ensureDailyScene() }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
        .environmentObject(store)
    }

    private var streakRow: some View {
        HStack {
            Image(systemName: "flame.fill").foregroundColor(AppTheme.accent)
            Text(store.currentStreak == 0 ? "No streak yet — capture today" : "\(store.currentStreak)-day streak")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(14)
        .background(AppTheme.surface.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
    }

    private func dailyCard(_ card: SceneCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scene of the day")
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.accent)
            NavigationLink(value: card) {
                VStack(alignment: .leading, spacing: 8) {
                    SceneArtwork(card: card)
                        .frame(height: 150)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text(card.title).font(.headline).foregroundColor(.white)
                    Text(card.seedPrompt).font(.subheadline).foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            Button("Writing sprint") { sprintCard = card }
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundColor(AppTheme.accent)
        }
        .padding(12)
        .background(AppTheme.slate, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var favoritesShelf: some View {
        if !store.favoriteCards.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Favorites")
                    .font(.headline)
                    .foregroundColor(.white)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.favoriteCards) { card in
                            NavigationLink(value: card) {
                                VStack(alignment: .leading, spacing: 6) {
                                    SceneArtwork(card: card)
                                        .frame(width: 118, height: 86)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    Text(card.title)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .frame(width: 118, alignment: .leading)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var chronicleFilters: some View {
        if !store.entries.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Chronicle")
                    .font(.headline)
                    .foregroundColor(.white)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip("All themes", selected: themeFilter == nil) { themeFilter = nil }
                        ForEach(themes, id: \.self) { theme in
                            filterChip(theme, selected: themeFilter == theme) {
                                themeFilter = themeFilter == theme ? nil : theme
                            }
                        }
                    }
                }
                HStack(spacing: 8) {
                    ForEach(["lightbulb", "camera", "moon", "flame"], id: \.self) { icon in
                        Button {
                            iconFilter = iconFilter == icon ? nil : icon
                        } label: {
                            Text(emoji(icon))
                                .padding(8)
                                .background(iconFilter == icon ? AppTheme.accent.opacity(0.35) : AppTheme.surface, in: Circle())
                        }
                        .frame(minWidth: 44, minHeight: 44)
                    }
                }
            }
        }
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(selected ? AppTheme.accent.opacity(0.35) : AppTheme.surface, in: Capsule())
                .foregroundColor(.white)
        }
    }

    private func navRow(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(AppTheme.accent)
            Text(title).font(.headline).foregroundColor(.white).lineLimit(1)
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
        .padding(14)
        .background(AppTheme.slate, in: RoundedRectangle(cornerRadius: 10))
    }

    private var themes: [String] {
        Array(Set(store.entries.map(\.theme))).sorted()
    }

    private var filteredEntries: [ChronicleEntry] {
        store.entries.filter { entry in
            let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let textOk = q.isEmpty
                || entry.title.localizedCaseInsensitiveContains(q)
                || entry.theme.localizedCaseInsensitiveContains(q)
                || entry.prompts.contains { $0.localizedCaseInsensitiveContains(q) }
            let themeOk = themeFilter == nil || entry.theme == themeFilter
            let iconOk = iconFilter == nil || entry.icon == iconFilter
            return textOk && themeOk && iconOk
        }
    }

    private func emoji(_ icon: String) -> String {
        switch icon {
        case "camera": return "📷"
        case "moon": return "🌙"
        case "flame": return "🔥"
        default: return "💡"
        }
    }
}
