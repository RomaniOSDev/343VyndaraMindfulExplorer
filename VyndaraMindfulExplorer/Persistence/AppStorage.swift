import Foundation
import Combine
import UIKit
import UserNotifications

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

enum SceneLibrary {
    static let cards: [SceneCard] = [
        SceneCard(id: "camera", imageName: "BannerCamera", title: "Night lens", seedPrompt: "Who is watching from the other side of the glass?", tags: ["noir", "city"]),
        SceneCard(id: "type", imageName: "BannerTypewriter", title: "Blank page", seedPrompt: "The first sentence you refuse to write.", tags: ["voice", "secret"]),
        SceneCard(id: "board", imageName: "BannerBoard", title: "Pin wall", seedPrompt: "Connect three images into one character's memory.", tags: ["collage", "memory"])
    ]
}

enum CaptureReminders {
    static let requestId = "daily-capture"

    static func apply(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestId])
        guard enabled else { return }
        center.requestAuthorization(options: [.alert, .sound]) { ok, _ in
            guard ok else { return }
            let content = UNMutableNotificationContent()
            content.title = "Don't skip the capture"
            content.body = "One scene. One prompt. Keep the streak."
            content.sound = .default
            var comps = DateComponents()
            comps.hour = 20
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            center.add(UNNotificationRequest(identifier: requestId, content: content, trigger: trigger))
        }
    }
}

@MainActor
final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var entries: [ChronicleEntry] = []
    @Published var photoPrompts: [PhotoPrompt] = []
    @Published var favorites: [String] = []
    @Published var recentlyViewed: [String] = []
    @Published var customScenes: [SceneCard] = []
    @Published var captureDays: [String] = []
    @Published var dailySceneId: String = ""
    @Published var remindersEnabled = false

    private let defaults = UserDefaults.standard
    private let entriesKey = "entries"
    private let promptsKey = "photoPrompts"
    private let favKey = "favorites"
    private let recentKey = "recentlyViewed"
    private let customKey = "customScenes"
    private let captureKey = "captureDays"
    private let dailyIdKey = "dailySceneId"
    private let dailyDateKey = "dailySceneDate"
    private let remindersKey = "remindersEnabled"
    private var dailySceneDate = ""

    var allScenes: [SceneCard] { SceneLibrary.cards + customScenes }

    var favoriteCards: [SceneCard] {
        favorites.compactMap { id in allScenes.first { $0.id == id } }
    }

    var lastViewedCard: SceneCard? {
        guard let id = recentlyViewed.first else { return nil }
        return card(id: id)
    }

    var dailyScene: SceneCard? { card(id: dailySceneId) ?? allScenes.first }

    var currentStreak: Int {
        let cal = Calendar.current
        let set = Set(captureDays)
        var day = cal.startOfDay(for: Date())
        if !set.contains(Self.dayString(day)) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while set.contains(Self.dayString(day)) {
            streak += 1
            guard let previous = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    private init() { load() }

    func load() {
        entries = decode([ChronicleEntry].self, key: entriesKey) ?? []
        photoPrompts = decode([PhotoPrompt].self, key: promptsKey) ?? []
        favorites = defaults.stringArray(forKey: favKey) ?? []
        recentlyViewed = defaults.stringArray(forKey: recentKey) ?? []
        customScenes = decode([SceneCard].self, key: customKey) ?? []
        captureDays = defaults.stringArray(forKey: captureKey) ?? []
        dailySceneId = defaults.string(forKey: dailyIdKey) ?? ""
        dailySceneDate = defaults.string(forKey: dailyDateKey) ?? ""
        remindersEnabled = defaults.bool(forKey: remindersKey)
        ensureDailyScene()
        if remindersEnabled { CaptureReminders.apply(enabled: true) }
    }

    func save() {
        encode(entries, key: entriesKey)
        encode(photoPrompts, key: promptsKey)
        encode(customScenes, key: customKey)
        defaults.set(favorites, forKey: favKey)
        defaults.set(recentlyViewed, forKey: recentKey)
        defaults.set(captureDays, forKey: captureKey)
        defaults.set(dailySceneId, forKey: dailyIdKey)
        defaults.set(dailySceneDate, forKey: dailyDateKey)
        defaults.set(remindersEnabled, forKey: remindersKey)
    }

    func card(id: String) -> SceneCard? {
        allScenes.first { $0.id == id }
    }

    func ensureDailyScene() {
        let today = Self.dayString(Date())
        if dailySceneDate == today, card(id: dailySceneId) != nil { return }
        dailySceneId = (allScenes.randomElement() ?? SceneLibrary.cards[0]).id
        dailySceneDate = today
        save()
    }

    func upsertEntry(_ entry: ChronicleEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        recordCapture()
        save()
    }

    func deleteEntry(_ id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func prompt(for imageName: String) -> PhotoPrompt? {
        photoPrompts.first { $0.imageName == imageName }
    }

    func upsertPrompt(_ item: PhotoPrompt) {
        var next = item
        if let index = photoPrompts.firstIndex(where: { $0.imageName == item.imageName }) {
            let existing = photoPrompts[index]
            if existing.prompt != item.prompt {
                var history = existing.history
                history.insert(PromptRevision(id: UUID(), prompt: existing.prompt, savedAt: existing.updatedAt), at: 0)
                if history.count > 20 { history = Array(history.prefix(20)) }
                next.history = history
            } else {
                next.history = existing.history
            }
            photoPrompts[index] = next
        } else {
            photoPrompts.append(next)
        }
        recordCapture()
        save()
    }

    func restoreRevision(_ revision: PromptRevision, for imageName: String) {
        guard let current = prompt(for: imageName) else { return }
        let item = PhotoPrompt(id: current.id, imageName: current.imageName, caption: current.caption, prompt: revision.prompt, updatedAt: Date(), history: current.history)
        upsertPrompt(item)
    }

    func addEntry(from card: SceneCard, note: String? = nil) {
        let prompt = prompt(for: card.imageName)?.prompt ?? card.seedPrompt
        var prompts = [prompt]
        if let note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            prompts.append(note.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        let entry = ChronicleEntry(id: UUID(), title: card.title, prompts: prompts, icon: "lightbulb", theme: card.tags.first ?? "scene")
        upsertEntry(entry)
        markViewed(card.id)
    }

    func toggleFavorite(_ id: String) {
        if let index = favorites.firstIndex(of: id) {
            favorites.remove(at: index)
        } else {
            favorites.append(id)
        }
        save()
    }

    func markViewed(_ id: String) {
        recentlyViewed.removeAll { $0 == id }
        recentlyViewed.insert(id, at: 0)
        if recentlyViewed.count > 12 { recentlyViewed = Array(recentlyViewed.prefix(12)) }
        save()
    }

    @discardableResult
    func addCustomScene(imageData: Data, title: String, seed: String) -> SceneCard? {
        guard let raw = UIImage(data: imageData) else { return nil }
        let image = Self.downscale(raw)
        guard let jpeg = image.jpegData(compressionQuality: 0.82) else { return nil }
        let fileName = "\(UUID().uuidString).jpg"
        let url = scenesDirectory.appendingPathComponent(fileName)
        do { try jpeg.write(to: url, options: .atomic) } catch { return nil }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSeed = seed.trimmingCharacters(in: .whitespacesAndNewlines)
        let card = SceneCard(
            id: "custom-\(UUID().uuidString)",
            imageName: fileName,
            title: trimmedTitle.isEmpty ? "Custom scene" : trimmedTitle,
            seedPrompt: trimmedSeed.isEmpty ? "What memory lives in this frame?" : trimmedSeed,
            tags: ["custom"],
            isCustom: true
        )
        customScenes.insert(card, at: 0)
        recordCapture()
        save()
        return card
    }

    func deleteCustomScene(_ id: String) {
        guard let card = customScenes.first(where: { $0.id == id }) else { return }
        let url = scenesDirectory.appendingPathComponent(card.imageName)
        try? FileManager.default.removeItem(at: url)
        customScenes.removeAll { $0.id == id }
        favorites.removeAll { $0 == id }
        recentlyViewed.removeAll { $0 == id }
        photoPrompts.removeAll { $0.imageName == card.imageName }
        if dailySceneId == id { dailySceneDate = ""; ensureDailyScene() }
        save()
    }

    func uiImage(for card: SceneCard) -> UIImage? {
        if card.isCustom {
            return UIImage(contentsOfFile: scenesDirectory.appendingPathComponent(card.imageName).path)
        }
        return UIImage(named: card.imageName)
    }

    func setRemindersEnabled(_ enabled: Bool) {
        remindersEnabled = enabled
        save()
        CaptureReminders.apply(enabled: enabled)
    }

    func resetAllData() {
        [entriesKey, promptsKey, favKey, recentKey, customKey, captureKey, dailyIdKey, dailyDateKey, remindersKey].forEach { defaults.removeObject(forKey: $0) }
        try? FileManager.default.removeItem(at: scenesDirectory)
        entries = []
        photoPrompts = []
        favorites = []
        recentlyViewed = []
        customScenes = []
        captureDays = []
        dailySceneId = ""
        dailySceneDate = ""
        remindersEnabled = false
        CaptureReminders.apply(enabled: false)
        ensureDailyScene()
        NotificationCenter.default.post(name: .dataReset, object: nil)
    }

    func recordCapture() {
        let today = Self.dayString(Date())
        if !captureDays.contains(today) {
            captureDays.append(today)
        }
    }

    private var scenesDirectory: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Scenes", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func dayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private static func downscale(_ image: UIImage, maxSide: CGFloat = 1600) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxSide, longest > 0 else { return image }
        let scale = maxSide / longest
        let new = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: new)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: new)) }
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
