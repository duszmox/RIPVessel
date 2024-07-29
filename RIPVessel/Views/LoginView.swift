//
//  LoginView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import SwiftUI

struct LoginView: View {
    @StateObject private var vm = ViewModel()
    
    
    var body: some View {
        VStack {
            Text("Login")
                    .font(.title)
                .bold()
                .padding()
            
            TextField("Username", text: $vm.username)
                .padding()
                .roundedBorder(cornerRadius: 15, borderColor: .gray, lineWidth: 1)
        
            SecureField("Password", text: $vm.password)
                .padding()
                .roundedBorder(cornerRadius: 15, borderColor: .gray, lineWidth: 1)
            
            Button("Login", action: {
                Task {
                   await vm.login()
                }
            })
        }.padding()
    }
}

#Preview {
    LoginView()
}
