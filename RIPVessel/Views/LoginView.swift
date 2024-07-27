//
//  LoginView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import SwiftUI

struct LoginView: View {
    @StateObject private var vm = ViewModel()
    
    @FocusState private var usernameFocused: Bool
    @FocusState private var passwordFocused: Bool
    
    var body: some View {
        VStack {
            Text("Login")
                    .font(.title)
                .bold()
                .padding()
            
            TextField("Username", text: $vm.username)
                .padding()
                .roundedBorder(cornerRadius: 15, borderColor: .gray, lineWidth: 1)
                .focused($usernameFocused)
                .onTapGesture {
                    if !usernameFocused {
                        usernameFocused.toggle()
                        passwordFocused.toggle()
                    }
                   
                }
                
        
            SecureField("Password", text: $vm.password)
                .padding()
                .roundedBorder(cornerRadius: 15, borderColor: .gray, lineWidth: 1)
                .focused($passwordFocused)
                .onTapGesture {
                    if !passwordFocused {
                        usernameFocused.toggle()
                        passwordFocused.toggle()
                    }
                }
            
            Button("Login", action: {
                vm.login()
            })
        }.padding()
    }
}

#Preview {
    LoginView()
}
