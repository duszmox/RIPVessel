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
        
        func login() {
            
        }
    }
}
