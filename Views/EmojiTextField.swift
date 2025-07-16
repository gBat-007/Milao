import SwiftUI

struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextField

        init(_ parent: EmojiTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            // Filter to just first emoji-like character
            if let first = textField.text?.first {
                parent.text = String(first)
                textField.text = parent.text
            } else {
                parent.text = ""
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.font = UIFont.systemFont(ofSize: 28)
        textField.textAlignment = .center
        textField.keyboardType = .default // Let the user choose emoji keyboard
        textField.returnKeyType = .done
        textField.tintColor = .clear
        textField.text = text
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
}
