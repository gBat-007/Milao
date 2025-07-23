import SwiftUI
import UIKit

struct EmojiKeyboardButton: UIViewControllerRepresentable {
    @Binding var emoji: String

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiKeyboardButton
        var textField: UITextField?

        init(_ parent: EmojiKeyboardButton) {
            self.parent = parent
        }

        @objc func openKeyboard() {
            textField?.becomeFirstResponder()
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            guard let text = textField.text else { return }

            if let first = text.first, first.isSingleEmoji {
                parent.emoji = String(first)
                textField.text = ""
                textField.resignFirstResponder()
            } else {
                textField.text = ""
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view = UIView()

        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .default
        textField.tintColor = .clear
        textField.backgroundColor = .clear
        textField.textColor = .clear
        textField.isHidden = true

        context.coordinator.textField = textField
        vc.view.addSubview(textField)

        let button = UIButton(type: .system)
        button.setTitle(emoji.isEmpty ? "😀" : emoji, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 36)
        button.backgroundColor = UIColor.systemGray5
        button.layer.cornerRadius = 12
        button.addTarget(context.coordinator, action: #selector(Coordinator.openKeyboard), for: .touchUpInside)

        vc.view.addSubview(button)

        textField.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: vc.view.topAnchor),
            textField.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            textField.widthAnchor.constraint(equalToConstant: 0),
            textField.heightAnchor.constraint(equalToConstant: 0),

            button.topAnchor.constraint(equalTo: vc.view.topAnchor),
            button.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
        ])

        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        let button = uiViewController.view.subviews.compactMap { $0 as? UIButton }.first
        if button?.title(for: .normal) != emoji {
            button?.setTitle(emoji.isEmpty ? "😀" : emoji, for: .normal)
        }
    }
}

private extension Character {
    var isSingleEmoji: Bool {
        return String(self).unicodeScalars.first?.properties.isEmojiPresentation == true
    }
}
