//
//  AttributedText.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 10. 27..
//

import SwiftUI

struct AttributedText: UIViewRepresentable {
    private let attributedString: NSAttributedString

    init(_ attributedString: NSAttributedString) {
        self.attributedString = attributedString
    }

    func makeUIView(context: Context) -> CustomTextView {
        let uiTextView = CustomTextView()
        uiTextView.backgroundColor = .clear
        uiTextView.isEditable = false
        uiTextView.isScrollEnabled = false
        uiTextView.isSelectable = true
        uiTextView.textContainerInset = .zero
        uiTextView.textContainer.lineFragmentPadding = 0
        uiTextView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        uiTextView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        uiTextView.updateAttributedText(attributedString, for: uiTextView.traitCollection)
        return uiTextView
    }

    func updateUIView(_ uiTextView: CustomTextView, context: Context) {
        uiTextView.updateAttributedText(attributedString, for: uiTextView.traitCollection)
    }

    class CustomTextView: UITextView {
        func updateAttributedText(_ attributedString: NSAttributedString, for traitCollection: UITraitCollection) {
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
            let systemFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
            let textColor: UIColor = traitCollection.userInterfaceStyle == .dark ? .white : .black

            mutableAttributedString.addAttributes([
                .font: systemFont,
                .foregroundColor: textColor
            ], range: NSRange(location: 0, length: mutableAttributedString.length))

            self.attributedText = mutableAttributedString
            self.invalidateIntrinsicContentSize()
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAttributedText(self.attributedText ?? NSAttributedString(), for: traitCollection)
            }
        }
    }
}

struct AsyncAttributedTextView: View {
    let htmlString: String
    @State private var attributedString: NSAttributedString?

    var body: some View {
        Group {
            if let attributedString = attributedString {
                AttributedText(attributedString)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Loading...")
            }
        }
        .task {
            await loadAttributedString()
        }
    }

    @MainActor
    private func loadAttributedString() async {
        let loadedAttributedString = await createAttributedString(from: htmlString)
        self.attributedString = loadedAttributedString
    }

    private func createAttributedString(from html: String) async -> NSAttributedString? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = Data(html.utf8)
                    let attributedString = try NSAttributedString(
                        data: data,
                        options: [
                            .documentType: NSAttributedString.DocumentType.html,
                            .characterEncoding: String.Encoding.utf8.rawValue
                        ],
                        documentAttributes: nil
                    )
                    continuation.resume(returning: attributedString)
                } catch {
                    continuation.resume(returning: NSAttributedString(string: "Invalid HTML content"))
                }
            }
        }
    }
}
