//
//  RIPVesselApp.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
        
    static var orientationLock = UIInterfaceOrientationMask.all //By default you want all your views to rotate freely

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

@main
struct RIPVesselApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
               NavigationStack(path: $router.navPath) {
               RecentsView().navigationDestination(for: Router.Destination.self) { destination in
                   switch destination {
                   case .video(let post):
                       VideoView(post: post)
                   }
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
