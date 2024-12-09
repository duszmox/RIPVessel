//
//  MainView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 12. 09..
//
import SwiftUI

struct MainView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var router = Router.shared
    
    @State private var activeTab: Tab = .recents
    @State private var config: PlayerConfig = .init()
    var body: some View {
           if auth.loggedIn {
               ZStack(alignment: .bottom) {
                   TabView (selection: $activeTab) {
                       NavigationStack {
                           RecentsPageView(playerConfig: $config)
                       }.setupTab(.recents)
                       NavigationStack {
                           CreatorsView(playerConfig: $config)
                       }.setupTab(.creators)
                       NavigationStack {
                           AccountView()
                       }.setupTab(.you)
                   }.padding(.bottom, tabBarHeight(withSafeArea: true))
                                      
                   /// MiniPlayer View
                   GeometryReader {
                       let size = $0.size

                       if config.showMiniPlayer {
                           MiniPlayerView(size: size, config: $config) {
                               withAnimation(.easeInOut(duration: 0.3)) {
                                   config.showMiniPlayer = false
                               }
                               DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                   config.resetPosition()
                                   config.selectedPlayerItem = nil
                               }
                           }
                       }
                   }
                   
                   CustomTabBar()
                       .offset(y: config.showMiniPlayer ? tabBarHeight(withSafeArea: true) - (config.progress * tabBarHeight(withSafeArea: true)) : 0)
               }.ignoresSafeArea(.all, edges: .bottom)
               
           } else {
               LoginView()
           }
       }
    
    /// Custom Tab Bar
    @ViewBuilder
    func CustomTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                VStack(spacing: 4) {
                    Image(systemName: tab.symbol)
                        .font(.title3)
                    Text(tab.rawValue)
                        .font(.caption2)
                }
                .foregroundStyle(activeTab == tab ? Color.primary : .gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(.rect)
                .onTapGesture {
                    activeTab = tab
                }
            }
        }
        .frame(height: tabBarHeight())
        .overlay(alignment: .top) {
            Divider()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .frame(height: tabBarHeight(withSafeArea: true))
        .background(.background)
    }
    
    private func tabBarHeight(withSafeArea: Bool = false) -> CGFloat {
        if withSafeArea {
            return 49 + safeArea.bottom
        } else {
            return 49
        }
    }
}
