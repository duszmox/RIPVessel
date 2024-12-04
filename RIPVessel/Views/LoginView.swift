//
//  LoginView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 07. 27..
//

import SwiftUI

struct LoginView: View {
    @StateObject private var vm = ViewModel()
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, password
    }
    
    var body: some View {
        ZStack {
            // Background Color
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("RIPVessel")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                CustomTextField(
                    placeholder: "Username",
                    text: $vm.username,
                    iconName: "person.fill",
                    isSecure: false
                )
                .focused($focusedField, equals: .username)
                
                CustomTextField(
                    placeholder: "Password",
                    text: $vm.password,
                    iconName: "lock.fill",
                    isSecure: true
                )
                .focused($focusedField, equals: .password)
                
                Button(action: {
                    Task {
                        await vm.login()
                    }
                }) {
                    Text("Login")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vm.isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!vm.isFormValid)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var iconName: String
    var isSecure: Bool
    @State private var isEditing = false
    @State private var showPassword = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.gray)
            
            if isSecure && !showPassword {
                SecureField(placeholder, text: $text)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
            } else {
                TextField(placeholder, text: $text)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
            }
            
            if isSecure {
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    LoginView()
}
