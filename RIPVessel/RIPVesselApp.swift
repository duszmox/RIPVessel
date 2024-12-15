//
//  RIPVesselApp.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import SwiftUI

@main
struct RIPVesselApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            MainView().environmentObject(AuthService.shared)

        }
    }
}
