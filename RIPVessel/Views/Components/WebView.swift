//
//  WebView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 31..
//
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
  @Binding var text: String
   
  func makeUIView(context: Context) -> WKWebView {
    return WKWebView()
  }
   
  func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.loadHTMLString(text, baseURL: nil)
  }
}
