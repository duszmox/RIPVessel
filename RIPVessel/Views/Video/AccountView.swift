//
//  AccountView.swift
//  RIPVessel
//
//  Created by Gyula Kiri on 2024. 12. 04..
//

import SwiftUI

struct AccountView: View {
    @StateObject private var vm = ViewModel()
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                IconView(url: UserDefaultsService.shared.user?.profileImage.path ?? "", size: CGSize(width: 120, height: 120))
                    .frame(width: 120, height: 120)
                    .roundedBorder(cornerRadius: 120, borderColor: .black, lineWidth: 0)
                    .padding(.top, 50)
                
                Text(UserDefaultsService.shared.user?.username ?? "")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Divider()
                    .padding(.horizontal)
                Text("Subscribed creators:")
                ForEach(vm.creators, id: \.id) { creator in
                    HStack {
                        IconView(url: creator.icon.path, size: CGSize(width: 44, height: 44)).frame(width: 44, height: 44).clipShape(Circle())
                        Text(creator.title)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showLogoutAlert = true
                }) {
                    Text("Log Out")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .alert(isPresented: $showLogoutAlert) {
                    Alert(
                        title: Text("Confirm Logout"),
                        message: Text("Are you sure you want to log out?"),
                        primaryButton: .destructive(Text("Log Out")) {
                            Task {
                                do {
                                    try await AuthService.shared.logout()
                                }
                                catch {
                                    print("Error: \(error)")
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await vm.fetchSubscriptions()
                }
                
            }
        }
    }
}
