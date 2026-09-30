import SwiftUI
import UIKit

extension View {
    func screenBackdrop(_ imageName: String = "BgWorkshop") -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .opacity(0.36)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }

    func clearScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
    }

    func dismissKeyboardOnTap() -> some View {
        background(KeyboardDismissInstaller())
    }
}

private final class KeyboardDismissCoordinator: NSObject, UIGestureRecognizerDelegate {
    @objc func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UITextField || current is UITextView { return false }
            view = current.superview
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}

private struct KeyboardDismissInstaller: UIViewRepresentable {
    func makeCoordinator() -> KeyboardDismissCoordinator { KeyboardDismissCoordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            guard let host = view.superview else { return }
            if host.gestureRecognizers?.contains(where: { $0.name == "dismiss-keyboard-tap" }) == true { return }
            let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(KeyboardDismissCoordinator.dismissKeyboard))
            tap.cancelsTouchesInView = false
            tap.delegate = context.coordinator
            tap.name = "dismiss-keyboard-tap"
            host.addGestureRecognizer(tap)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
