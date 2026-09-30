import Foundation
import Combine
import UIKit
import UserNotifications

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

enum PairingReminders {
    static let requestId = "evening-pairing"

    static func apply(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestId])
        guard enabled else { return }
        center.requestAuthorization(options: [.alert, .sound]) { ok, _ in
            guard ok else { return }
            let content = UNMutableNotificationContent()
            content.title = "Two frames. One scene."
            content.body = "Pick a pair and lock a draft before the day closes."
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

    @Published var cards: [WrittenScene] = []
    @Published var customFrames: [FrameShot] = []
    @Published var draft = WorkshopDraft()
    @Published var remindersEnabled = false
    @Published var homeTick = 0

    private let defaults = UserDefaults.standard
    private let cardsKey = "workshop_cards_v1"
    private let customKey = "workshop_custom_frames_v1"
    private let draftKey = "workshop_draft_v1"
    private let remindersKey = "pairing_reminders_v1"

    var allFrames: [FrameShot] { FrameLibrary.shots + customFrames }

    private init() { load() }

    func load() {
        cards = decode([WrittenScene].self, key: cardsKey) ?? []
        customFrames = decode([FrameShot].self, key: customKey) ?? []
        draft = decode(WorkshopDraft.self, key: draftKey) ?? WorkshopDraft()
        remindersEnabled = defaults.bool(forKey: remindersKey)
        if remindersEnabled { PairingReminders.apply(enabled: true) }
    }

    func save() {
        encode(cards, key: cardsKey)
        encode(customFrames, key: customKey)
        encode(draft, key: draftKey)
        defaults.set(remindersEnabled, forKey: remindersKey)
    }

    func frame(id: String) -> FrameShot? {
        allFrames.first { $0.id == id }
    }

    func uiImage(for frame: FrameShot) -> UIImage? {
        if frame.isCustom {
            return UIImage(contentsOfFile: framesDirectory.appendingPathComponent(frame.imageName).path)
        }
        return UIImage(named: frame.imageName)
    }

    func setPair(a: FrameShot?, b: FrameShot?) {
        draft.frameA = a
        draft.frameB = b
        save()
    }

    func toggleFrame(_ frame: FrameShot) {
        if draft.frameA?.id == frame.id {
            draft.frameA = nil
        } else if draft.frameB?.id == frame.id {
            draft.frameB = nil
        } else if draft.frameA == nil {
            draft.frameA = frame
        } else if draft.frameB == nil {
            draft.frameB = frame
        } else {
            draft.frameB = frame
        }
        save()
    }

    func updateBeats(_ beats: SceneBeats) {
        draft.beats = beats
        save()
    }

    func discardDraft() {
        draft = WorkshopDraft()
        save()
    }

    func completeScene(draftText: String, minutes: Int) {
        guard let a = draft.frameA, let b = draft.frameB, draft.beats.isComplete else { return }
        let scene = WrittenScene(
            id: UUID(),
            frameA: a,
            frameB: b,
            beats: draft.beats,
            draft: draftText.trimmingCharacters(in: .whitespacesAndNewlines),
            minutes: minutes,
            finishedAt: Date()
        )
        cards.insert(scene, at: 0)
        draft = WorkshopDraft()
        save()
        homeTick += 1
        CaptureHaptics.capture()
    }

    func deleteCard(_ id: UUID) {
        cards.removeAll { $0.id == id }
        save()
    }

    @discardableResult
    func addCustomFrame(imageData: Data) -> FrameShot? {
        guard let raw = UIImage(data: imageData) else { return nil }
        let image = Self.downscale(raw)
        guard let jpeg = image.jpegData(compressionQuality: 0.82) else { return nil }
        let fileName = "\(UUID().uuidString).jpg"
        let url = framesDirectory.appendingPathComponent(fileName)
        do { try jpeg.write(to: url, options: .atomic) } catch { return nil }
        let index = customFrames.count + 1
        let shot = FrameShot(
            id: "custom-\(UUID().uuidString)",
            imageName: fileName,
            title: "Picked frame \(index)",
            isCustom: true
        )
        customFrames.insert(shot, at: 0)
        save()
        return shot
    }

    func setRemindersEnabled(_ enabled: Bool) {
        remindersEnabled = enabled
        save()
        PairingReminders.apply(enabled: enabled)
    }

    func resetAllData() {
        [cardsKey, customKey, draftKey, remindersKey].forEach { defaults.removeObject(forKey: $0) }
        try? FileManager.default.removeItem(at: framesDirectory)
        cards = []
        customFrames = []
        draft = WorkshopDraft()
        remindersEnabled = false
        PairingReminders.apply(enabled: false)
        NotificationCenter.default.post(name: .dataReset, object: nil)
        save()
    }

    private var framesDirectory: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Frames", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
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
