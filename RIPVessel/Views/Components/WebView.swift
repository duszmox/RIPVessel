//
//  WebView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 31..
//
import SwiftUI
@preconcurrency import WebKit

struct WebView: UIViewRepresentable {
    @Binding var text: String
    @Binding var contentHeight: CGFloat

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.parent.contentHeight = 40
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Get the system font
        let systemFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        let fontName = systemFont.fontName
        let fontSize = systemFont.pointSize

        // Detect the user interface style
        let textColor: String
        if UIScreen.main.traitCollection.userInterfaceStyle == .dark {
            textColor = "white"
        } else {
            textColor = "black"
        }

        // Inject CSS into the HTML content
        let styledHTML = """
        <html>
        <head>
        <style>
        body {
            font-family: '\(fontName)';
            font-size: \(fontSize)px;
            color: \(textColor);
        }
        </style>
        </head>
        <body>
        \(text)
        </body>
        </html>
        """

        uiView.loadHTMLString(styledHTML, baseURL: nil)
        uiView.isOpaque = false
        uiView.scrollView.isScrollEnabled = false
    }
}
