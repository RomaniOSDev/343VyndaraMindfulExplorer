import SwiftUI
import UniformTypeIdentifiers

enum CaptureHaptics {
    static func capture() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.7)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

struct SceneArtwork: View {
    @EnvironmentObject private var store: AppDataStore
    let card: SceneCard

    var body: some View {
        Group {
            if card.isCustom, let image = store.uiImage(for: card) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(card.imageName).resizable().scaledToFill()
            }
        }
    }
}

struct PickedImageData: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            PickedImageData(data: data)
        }
    }
}
