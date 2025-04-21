//
//  ContentView.swift
//  BeautyBookingApp
//
//  Created by huynh loc on 3/30/25.
//


import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var bookingVM = BookingViewModel()

    var body: some View {
        NavigationStack {
            if authVM.isAuthenticated {
                TabView {
                    NavigationStack { 
                        SalonFeedView()
                            .environmentObject(bookingVM)
                    }.tabItem { Label("Feed", systemImage: "house") }
                    NavigationStack { 
                        ProfileView()
                            .environmentObject(bookingVM)
                    }.tabItem { Label("Profile", systemImage: "person") }
                }
            } else {
                LoginView()
            }
        }
    }
}

#Preview(){
    ContentView()
        .environmentObject(AuthViewModel())
}
