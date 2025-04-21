//
//  LoginView.swift
//  BeautyBookingApp
//
//  Created by huynh loc on 3/30/25.
//


import SwiftUI
import FirebaseFirestore

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingPassword = false
    @State private var testUser: String = "Testing..."
    
    var body: some View {
        VStack(spacing: 25) {
            // Test data section
            //Text("Test Database Connection:")
            //    .font(.headline)
            //Text(testUser)
            //    .foregroundColor(.gray)
            
            // Logo/App Name Section
            VStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Text("Welcome Back")
                    .font(.title)
                    .bold()
                
                Text("Please sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 40)
            
            // Form Fields
            VStack(spacing: 16) {
                // Email Field
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.gray)
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Password Field
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                    if isShowingPassword {
                        TextField("Password", text: $password)
                    } else {
                        SecureField("Password", text: $password)
                    }
                    Button {
                        isShowingPassword.toggle()
                    } label: {
                        Image(systemName: isShowingPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Forgot Password Link
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        // Add forgot password action
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                }
            }
            
            // Login Button
            Button {
                authVM.signIn(email: email, password: password)
            } label: {
                HStack {
                    Text("Sign In")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top)
            
            // Sign Up Link
            NavigationLink {
                SignUpView()
            } label: {
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.gray)
                    Text("Sign Up")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .font(.subheadline)
            }
            .padding(.top)
            
            Spacer()
            
        }
        .padding(.horizontal)
        
    }
}

