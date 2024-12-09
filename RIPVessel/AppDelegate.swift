//
//  AppDelegate.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 12. 09..
//
import Foundation
import UIKit
#if DUSZMOX
import Shake
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
        
    static var orientationLock = UIInterfaceOrientationMask.portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    func application(
       _ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
           let env = ProcessInfo.processInfo.environment
           loadRocketSimConnect()
           #if DUSZMOX
           Shake.start(apiKey: env["SHAKE_API_KEY"] ?? "")
           #endif
           return true
     }
    
    static func rotateScreen(to orientation: UIInterfaceOrientationMask) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation)) { error in
            if let err = error as? UISceneError, err.code == .geometryRequestUnsupported {
                AppDelegate.orientationLock = .allButUpsideDown
                DispatchQueue.main.async {
                    self.rotateScreen(to: orientation)
                }
            }
            print("Error updating geometry: \(error)")
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

}
