//
//  LoginViewModel.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import Foundation

extension LoginView {
    class ViewModel: ObservableObject {
        @Published var username: String = ""
        @Published var password: String = ""
        var isFormValid: Bool {
            !username.isEmpty && !password.isEmpty
        }
        
        func login() async {
            do {
                try await AuthService.shared.signIn(username: username, password: password)
            }
            catch {
                print("Error: \(error)")
            }
        }
    }
}
