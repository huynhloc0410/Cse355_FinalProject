//
//  SignUpView.swift
//  BeautyBookingApp
//
//  Created by huynh loc on 3/30/25.
//


import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    // Form fields
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    
    // UI States
    @State private var isShowingPassword = false
    @State private var isShowingConfirmPassword = false
    @State private var isLoading = false
    
    // Validation
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        !fullName.isEmpty && 
        password == confirmPassword &&
        password.count >= 6
    }
    
    var body: some View {
        VStack(spacing: 25) {
            // Header Section
            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Text("Create Account")
                    .font(.title)
                    .bold()
                
                Text("Please fill in the details below")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 40)
            
            // Form Fields
            VStack(spacing: 16) {
                // Full Name Field
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Email Field
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.gray)
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
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
                
                // Confirm Password Field
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                    if isShowingConfirmPassword {
                        TextField("Confirm Password", text: $confirmPassword)
                    } else {
                        SecureField("Confirm Password", text: $confirmPassword)
                    }
                    Button {
                        isShowingConfirmPassword.toggle()
                    } label: {
                        Image(systemName: isShowingConfirmPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Error Message
            if let error = authVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5)
            }
            
            // Password requirements
            if !password.isEmpty && password.count < 6 {
                Text("Password must be at least 6 characters")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            if !password.isEmpty && password != confirmPassword {
                Text("Passwords do not match")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // Sign Up Button
            Button {
                isLoading = true
                authVM.signUp(email: email, password: password, fullName: fullName)
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
                            .font(.headline)
                        Image(systemName: "checkmark.circle")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!isFormValid || isLoading)
            .padding(.top)
            
            // Back to Login Link
            Button {
                dismiss()
            } label: {
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                    Text("Sign In")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .font(.subheadline)
            }
            .padding(.top)
            
            Spacer()
        }
        .padding(.horizontal)
        .navigationBarBackButtonHidden(true)
        .onChange(of: authVM.isAuthenticated) { newValue in
            if newValue {
                dismiss()
            }
        }
        .onChange(of: authVM.errorMessage) { _ in
            isLoading = false
        }
    }
}