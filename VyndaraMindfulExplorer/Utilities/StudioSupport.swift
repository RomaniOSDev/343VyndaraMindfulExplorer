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

struct FrameArtwork: View {
    @EnvironmentObject private var store: AppDataStore
    let frame: FrameShot

    var body: some View {
        Color.clear
            .overlay {
                artwork
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .accessibilityLabel(frame.title)
    }

    private var artwork: Image {
        if frame.isCustom, let image = store.uiImage(for: frame) {
            return Image(uiImage: image)
        }
        return Image(frame.imageName)
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
