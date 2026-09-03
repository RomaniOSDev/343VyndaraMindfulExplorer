import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Studio pulse")
                    .font(.custom("Georgia", size: 28))
                    .foregroundColor(.white)

                metricGrid

                chartCard("Scenes in play", subtitle: "How the library is used") {
                    Chart(librarySlices) { slice in
                        BarMark(
                            x: .value("Count", slice.count),
                            y: .value("Kind", slice.name)
                        )
                        .foregroundStyle(AppTheme.neon)
                    }
                    .chartXScale(domain: 0...max(1, (librarySlices.map(\.count).max() ?? 1)))
                    .frame(height: 180)
                    .chartXAxis { styledAxis() }
                    .chartYAxis { styledAxis() }
                }

                chartCard("Chronicle by theme", subtitle: "Where your annotations cluster") {
                    if themeSlices.isEmpty {
                        emptyChart("Add an annotation to see themes.")
                    } else {
                        Chart(themeSlices) { slice in
                            BarMark(
                                x: .value("Theme", slice.name),
                                y: .value("Entries", slice.count)
                            )
                            .foregroundStyle(AppTheme.accent)
                        }
                        .frame(height: 200)
                        .chartXAxis { styledAxis() }
                        .chartYAxis { styledAxis() }
                    }
                }

                chartCard("Prompt edits this week", subtitle: "Captions saved per day") {
                    Chart(weekSlices) { slice in
                        AreaMark(
                            x: .value("Day", slice.date, unit: .day),
                            y: .value("Saves", slice.count)
                        )
                        .foregroundStyle(AppTheme.primary.opacity(0.35))
                        LineMark(
                            x: .value("Day", slice.date, unit: .day),
                            y: .value("Saves", slice.count)
                        )
                        .foregroundStyle(AppTheme.accent)
                        PointMark(
                            x: .value("Day", slice.date, unit: .day),
                            y: .value("Saves", slice.count)
                        )
                        .foregroundStyle(AppTheme.accent)
                    }
                    .frame(height: 200)
                    .chartXAxis { styledAxis() }
                    .chartYAxis { styledAxis() }
                    .chartYScale(domain: 0...max(1, (weekSlices.map(\.count).max() ?? 1)))
                }

                chartCard("Capture streak days", subtitle: "Days you saved something") {
                    Chart(captureSlices) { slice in
                        BarMark(
                            x: .value("Day", slice.date, unit: .day),
                            y: .value("Captured", slice.count)
                        )
                        .foregroundStyle(AppTheme.neon)
                    }
                    .frame(height: 160)
                    .chartXAxis { styledAxis() }
                    .chartYAxis { styledAxis() }
                    .chartYScale(domain: 0...1)
                }
            }
            .padding(18)
        }
        .screenBackdrop("BgDesk")
        .navigationTitle("Statistics")
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metric("Annotations", "\(store.entries.count)", "book.closed")
            metric("Prompts", "\(store.photoPrompts.count)", "text.quote")
            metric("Favorites", "\(store.favorites.count)", "heart.fill")
            metric("Streak", "\(store.currentStreak)", "flame.fill")
            metric("Custom", "\(store.customScenes.count)", "photo.on.rectangle")
            metric("Viewed", "\(store.recentlyViewed.count)", "eye")
        }
    }

    private func metric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(AppTheme.accent)
            Text(value)
                .font(.custom("Georgia", size: 28))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.surface.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
    }

    private func chartCard<Content: View>(_ title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundColor(.white)
            Text(subtitle).font(.caption).foregroundColor(.secondary)
            content()
        }
        .padding(14)
        .background(AppTheme.slate, in: RoundedRectangle(cornerRadius: 12))
    }

    private func emptyChart(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
    }

    @AxisContentBuilder
    private func styledAxis() -> some AxisContent {
        AxisMarks { _ in
            AxisGridLine().foregroundStyle(Color.white.opacity(0.12))
            AxisTick().foregroundStyle(Color.white.opacity(0.3))
            AxisValueLabel().foregroundStyle(Color.white.opacity(0.7))
        }
    }

    private var librarySlices: [NamedCount] {
        [
            NamedCount(name: "Library", count: store.allScenes.count),
            NamedCount(name: "Viewed", count: store.recentlyViewed.count),
            NamedCount(name: "Favorited", count: store.favorites.count),
            NamedCount(name: "Prompted", count: store.photoPrompts.count)
        ]
    }

    private var themeSlices: [NamedCount] {
        Dictionary(grouping: store.entries, by: \.theme)
            .map { NamedCount(name: $0.key.isEmpty ? "untagged" : $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private var weekSlices: [DayCount] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset -> DayCount? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let count = store.photoPrompts.filter { cal.isDate($0.updatedAt, inSameDayAs: day) }.count
            return DayCount(date: day, count: count)
        }
    }

    private var captureSlices: [DayCount] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.calendar = cal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return (0..<7).reversed().compactMap { offset -> DayCount? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let hit = store.captureDays.contains(formatter.string(from: day))
            return DayCount(date: day, count: hit ? 1 : 0)
        }
    }
}

private struct NamedCount: Identifiable {
    var id: String { name }
    let name: String
    let count: Int
}

private struct DayCount: Identifiable {
    var id: Date { date }
    let date: Date
    let count: Int
}
