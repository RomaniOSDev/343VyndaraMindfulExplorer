import Foundation

struct FrameShot: Identifiable, Hashable, Codable {
    let id: String
    let imageName: String
    let title: String
    var isCustom: Bool

    init(id: String, imageName: String, title: String, isCustom: Bool = false) {
        self.id = id
        self.imageName = imageName
        self.title = title
        self.isCustom = isCustom
    }
}

struct SceneBeats: Codable, Hashable, Equatable {
    var watcher: String = ""
    var want: String = ""
    var obstacle: String = ""
    var turn: String = ""
    var lastLine: String = ""

    var filledCount: Int {
        [watcher, want, obstacle, turn, lastLine]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .count
    }

    var isComplete: Bool { filledCount == 5 }

    var lines: [(label: String, value: String)] {
        [
            ("Who is watching", watcher),
            ("What they want", want),
            ("What stands in the way", obstacle),
            ("The turn from A to B", turn),
            ("Last line spoken", lastLine)
        ]
    }
}

struct WrittenScene: Identifiable, Hashable, Codable {
    var id: UUID
    var frameA: FrameShot
    var frameB: FrameShot
    var beats: SceneBeats
    var draft: String
    var minutes: Int
    var finishedAt: Date

    var pairingTitle: String {
        "\(frameA.title) × \(frameB.title)"
    }
}

struct WorkshopDraft: Codable, Equatable {
    var frameA: FrameShot?
    var frameB: FrameShot?
    var beats: SceneBeats = SceneBeats()

    var hasPair: Bool { frameA != nil && frameB != nil }
}

enum FrameLibrary {
    static let shots: [FrameShot] = [
        FrameShot(id: "ferry", imageName: "FrameFerry", title: "Night crossing"),
        FrameShot(id: "underpass", imageName: "FrameUnderpass", title: "Sodium pool"),
        FrameShot(id: "laundry", imageName: "FrameLaundry", title: "Last dryer"),
        FrameShot(id: "escape", imageName: "FrameFireEscape", title: "Snow on iron"),
        FrameShot(id: "ticket", imageName: "FrameTicket", title: "Closed window"),
        FrameShot(id: "greenhouse", imageName: "FrameGreenhouse", title: "Glass weather"),
        FrameShot(id: "overpass", imageName: "FrameOverpass", title: "Above the lanes"),
        FrameShot(id: "corridor", imageName: "FrameCorridor", title: "Room service gone")
    ]
}

enum WorkshopRoute: Hashable {
    case pair
    case beats
}
