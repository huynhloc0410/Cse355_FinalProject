//
//  BeautyBookingApp.swift
//  BeautyBookingApp
//
//  Created by huynh loc on 3/30/25.
//


import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@main
struct BeautyBookingApp: App {
    @StateObject var authVM = AuthViewModel()
    
    init() {
        // Configure Firebase if not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            
            // Configure Firestore settings
            let settings = FirestoreSettings()
            settings.isPersistenceEnabled = true
            settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
            Firestore.firestore().settings = settings
            
            // Configure Storage
            let storage = Storage.storage()
            storage.maxUploadRetryTime = 60 // 60 seconds
            storage.maxDownloadRetryTime = 60 // 60 seconds
            
            print("Firebase configured successfully")
        }
        
        // For development debugging
        #if DEBUG
        print("Firebase App Configured in Debug Mode")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
