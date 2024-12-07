//
//  LoadingRecentPostView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 08. 03..
//
import SwiftUI

struct LoadingRecentPostView: View {
    @State private var startingColor: Color = Color("loadingColorPrimary")
    @State private var endingColor: Color = Color("loadingColorSecondary")
    @State private var isAnimating: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [startingColor, endingColor]),
                    startPoint: .init(x: 0, y: 0),
                    endPoint: .init(x: 0.5, y: 1)
                ))
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(8)
                .onAppear {
                    startAnimatingColors()
                }
                .onDisappear {
                    stopAnimatingColors()
                }
            
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [startingColor, endingColor]),
                    startPoint: .init(x: 0, y: 0),
                    endPoint: .init(x: 0.5, y: 1)
                ))
                .frame(height: 20)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [startingColor, endingColor]),
                    startPoint: .init(x: 0, y: 0),
                    endPoint: .init(x: 0.5, y: 1)
                ))
                .frame(height: 20)
                .padding(.trailing, 50)
        }
        .padding(4)
    }
    
    private func startAnimatingColors() {
        isAnimating = true
        animateColors()
    }
    
    private func stopAnimatingColors() {
        isAnimating = false
    }
    
    private func animateColors() {
        guard isAnimating else { return }

        withAnimation(Animation.easeInOut(duration: 1)) {
            startingColor = startingColor == startingColor ? endingColor : startingColor
            endingColor = endingColor == endingColor ? startingColor : endingColor
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.isAnimating {
                self.animateColors()
            }
        }
    }
}
