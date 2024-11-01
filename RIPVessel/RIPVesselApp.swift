//
//  RIPVesselApp.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import SwiftUI
import Shake

class AppDelegate: NSObject, UIApplicationDelegate {
        
    static var orientationLock = UIInterfaceOrientationMask.all //By default you want all your views to rotate freely

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    func application(
       _ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
           let env = ProcessInfo.processInfo.environment
           #if DUSZMOX
           Shake.start(apiKey: env["SHAKE_API_KEY"] ?? "")
           #endif
           return true
     }
}

@main
struct RIPVesselApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {
        loadRocketSimConnect()
    }
    var body: some Scene {
        WindowGroup {
            MainView().environmentObject(AuthService.shared)

        }
    }
}

struct MainView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var router = Router.shared

    var body: some View {
           if auth.loggedIn {
               TabView {
                   NavigationStack {
                       RecentsView()
                   }.tabItem {
                           Label("Recents", systemImage: "play.house.fill")
                       }
                   NavigationStack {
                       CreatorsView()
                   }.tabItem {
                           Label("Creators", systemImage: "books.vertical.fill")
                   }
               }
           } else {
               LoginView()
           }
       }
}

struct LoadingView: View {
    var body: some View {
        Text("Loading...")
            .padding()
    }
}

private func loadRocketSimConnect() {
    #if DEBUG
    guard (Bundle(path: "/Applications/RocketSim.app/Contents/Frameworks/RocketSimConnectLinker.nocache.framework")?.load() == true) else {
        print("Failed to load linker framework")
        return
    }
    print("RocketSim Connect successfully linked")
    #endif
}
