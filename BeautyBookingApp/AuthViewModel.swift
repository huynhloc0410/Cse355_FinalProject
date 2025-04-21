//
//  AuthViewModel.swift
//  BeautyBookingApp
//
//  Created by huynh loc on 3/30/25.
//


import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    init() {
        print("AuthViewModel initialized")
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            print("Auth state changed. User: \(user?.uid ?? "nil")")
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                if let user = user {
                    self?.fetchUserData(userId: user.uid)
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            if let user = result?.user {
                self?.fetchUserData(userId: user.uid)
            }
        }
    }
    
    func signUp(email: String, password: String, fullName: String) {
        print("Starting sign up process...")
        
        // Basic validation
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "All fields are required"
            }
            return
        }
        
        // Configure auth settings
        let auth = Auth.auth()
        
        print("Attempting to create user with email: \(email)")
        
        auth.createUser(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    print("Firebase Auth Error: \(error.code) - \(error.localizedDescription)")
                    
                    switch error.code {
                    case AuthErrorCode.emailAlreadyInUse.rawValue:
                        self?.errorMessage = "This email is already registered"
                    case AuthErrorCode.invalidEmail.rawValue:
                        self?.errorMessage = "Please enter a valid email address"
                    case AuthErrorCode.weakPassword.rawValue:
                        self?.errorMessage = "Password should be at least 6 characters"
                    default:
                        self?.errorMessage = "Error: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let userId = authResult?.user.uid else {
                    self?.errorMessage = "Failed to get user ID"
                    return
                }
                
                print("Successfully created user with ID: \(userId)")
                
                // Create user document in Firestore
                let userData: [String: Any] = [
                    "fullName": fullName,
                    "email": email,
                    "createdAt": FieldValue.serverTimestamp(),
                    "userId": userId,
                    "profileImageURL": ""  // Initialize with empty string
                ]
                
                self?.db.collection("users").document(userId).setData(userData) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Firestore Error: \(error.localizedDescription)")
                            self?.errorMessage = "Failed to save user data"
                            return
                        }
                        
                        print("Successfully saved user data to Firestore")
                        self?.isAuthenticated = true
                        self?.currentUser = User(
                            id: userId,
                            fullName: fullName,
                            email: email,
                            profileImageURL: nil
                        )
                    }
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func fetchUserData(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            if let data = snapshot?.data() {
                // Update current user data
                DispatchQueue.main.async {
                    self?.currentUser = User(
                        id: userId,
                        fullName: data["fullName"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        profileImageURL: data["profileImageURL"] as? String
                    )
                }
            }
        }
    }
}

// User model
struct User {
    let id: String
    let fullName: String
    let email: String
    let profileImageURL: String?
}
