//
//  AttributedText.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 10. 27..
//

import SwiftUI

struct CollapsibleAsyncAttributedTextView: View {
    let htmlString: String
    @State private var isExpanded: Bool = false
    @State private var attributedString: AttributedString?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading) {
            if let attributedString = attributedString {
                Text(attributedString)
                    .lineLimit(isExpanded ? nil : 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // Remove or adjust fixedSize if necessary
                    //.fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Loading...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Text(isExpanded ? "Show Less" : "Read More")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 5)
        }
        .task {
            await loadAttributedString(colorScheme: colorScheme)
        }
        .onChange(of: colorScheme) { newColorScheme in
            Task {
                await loadAttributedString(colorScheme: newColorScheme)
            }
        }
    }

    @MainActor
    private func loadAttributedString(colorScheme: ColorScheme) async {
        if let data = htmlString.data(using: .utf8) {
            do {
                // Create an NSAttributedString from HTML data
                let nsAttributedString = try NSMutableAttributedString(
                    data: data,
                    options: [
                        .documentType: NSAttributedString.DocumentType.html,
                        .characterEncoding: String.Encoding.utf8.rawValue
                    ],
                    documentAttributes: nil
                )
                
                // Define your custom UIFont and UIColor
                let uiFont = UIFont.systemFont(ofSize: 16) // Customize the font as needed
                let uiColor = colorScheme == .dark ? UIColor.white : UIColor.black

                // Apply custom font and color to the entire NSAttributedString
                nsAttributedString.addAttributes([
                    .font: uiFont,
                    .foregroundColor: uiColor
                ], range: NSRange(location: 0, length: nsAttributedString.length))

                // Convert NSAttributedString to AttributedString
                let attributedString = AttributedString(nsAttributedString)

                // Update the state
                self.attributedString = attributedString
            } catch {
                self.attributedString = AttributedString("Invalid HTML content")
            }
        } else {
            self.attributedString = AttributedString("Invalid HTML content")
        }
    }
}
