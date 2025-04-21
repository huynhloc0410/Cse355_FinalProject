//
//  ProfileView.swift
//  BeautyBookingApp
//
//  Created by huynh loc on 3/30/25.
//


import SwiftUI
import FirebaseStorage
import PhotosUI
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var bookingVM = BookingViewModel()
    @State private var showingEditProfile = false
    @State private var showingAppointments = false
    @State private var showingFavorites = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isUploading = false
    
    private let storage = Storage.storage()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile Header
                VStack(spacing: 15) {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                            )
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .foregroundColor(.blue)
                            .background(Circle().fill(Color.blue.opacity(0.1)))
                            .overlay(
                                Circle()
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                            )
                    }
                    
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text("Change Photo")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .disabled(isUploading)
                    
                    if let user = authVM.currentUser {
                        Text(user.fullName)
                            .font(.title2)
                            .bold()
                        
                        Text(user.email)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 20)
                
                // Profile Options
                VStack(spacing: 15) {
                    // Personal Info Section
                    GroupBox {
                        ProfileOptionRow(icon: "person.fill", title: "Personal Information") {
                            showingEditProfile.toggle()
                        }
                        
                        ProfileOptionRow(icon: "bell.fill", title: "Notifications", showDivider: false) {
                            // Add notifications action
                        }
                    }
                    
                    // Appointments Section
                    GroupBox {
                        ProfileOptionRow(icon: "calendar", title: "My Appointments") {
                            showingAppointments.toggle()
                        }
                        
                        ProfileOptionRow(icon: "heart.fill", title: "Favorite Salons", showDivider: false) {
                            showingFavorites.toggle()
                        }
                    }
                    
                    // Sign Out Button
                    Button {
                        authVM.signOut()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Sign Out")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showingAppointments) {
            AppointmentsView()
                .environmentObject(bookingVM)
        }
        .sheet(isPresented: $showingFavorites) {
            FavoriteSalonsView()
                .environmentObject(bookingVM)
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        profileImage = image
                        uploadProfileImage(image)
                    }
                }
            }
        }
        .onAppear {
            if let userId = authVM.currentUser?.id {
                bookingVM.fetchUserBookings(userId: userId)
                loadProfileImage()
            }
        }
        .onChange(of: authVM.currentUser?.id) { newUserId in
            if let userId = newUserId {
                bookingVM.fetchUserBookings(userId: userId)
                loadProfileImage()
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        guard let userId = authVM.currentUser?.id,
              let imageData = image.jpegData(compressionQuality: 0.5) else {
            print("Failed to get user ID or convert image to data")
            return
        }
        
        isUploading = true
        
        // Create a reference to the file with a more specific path
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(userId)/profile.jpg")
        
        // Create file metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload the file
        let uploadTask = profileImageRef.putData(imageData, metadata: metadata)
        
        // Listen for state changes, errors, and completion of the upload
        uploadTask.observe(.success) { snapshot in
            // Upload completed successfully
            print("Image uploaded successfully")
            
            // Get the download URL
            profileImageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    self.isUploading = false
                    return
                }
                
                guard let downloadURL = url else {
                    print("Download URL is nil")
                    self.isUploading = false
                    return
                }
                
                print("Got download URL: \(downloadURL.absoluteString)")
                
                // Update user document in Firestore
                let db = Firestore.firestore()
                db.collection("users").document(userId).setData([
                    "profileImageURL": downloadURL.absoluteString
                ], merge: true) { error in
                    self.isUploading = false
                    
                    if let error = error {
                        print("Error updating user document: \(error.localizedDescription)")
                        return
                    }
                    
                    print("Successfully updated profile image URL in Firestore")
                    
                    // Update the current user object
                    DispatchQueue.main.async {
                        self.authVM.currentUser = User(
                            id: userId,
                            fullName: self.authVM.currentUser?.fullName ?? "",
                            email: self.authVM.currentUser?.email ?? "",
                            profileImageURL: downloadURL.absoluteString
                        )
                    }
                }
            }
        }
        
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                print("Error uploading image: \(error.localizedDescription)")
                print("Error details: \(error)")
            }
            self.isUploading = false
        }
    }
    
    private func loadProfileImage() {
        if let profileImageURL = authVM.currentUser?.profileImageURL,
           let url = URL(string: profileImageURL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        profileImage = image
                    }
                }
            }.resume()
        }
    }
}

// Helper view for profile options
struct ProfileOptionRow: View {
    let icon: String
    let title: String
    var showDivider: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 8)
        }
        
        if showDivider {
            Divider()
        }
    }
}

// Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    @State private var fullName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                    
                    if let user = authVM.currentUser {
                        Text(user.email)
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        // Add save changes functionality
                        dismiss()
                    }
                }
                
                Section {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let user = authVM.currentUser {
                    fullName = user.fullName
                }
            }
        }
    }
}

// Add this new view for displaying appointments
struct AppointmentsView: View {
    @EnvironmentObject var bookingVM: BookingViewModel
    @Environment(\.dismiss) var dismiss
    @State private var bookingToDelete: Booking?
    @State private var showDeleteAlert = false
    
    var futureBookings: [Booking] {
        let filtered = bookingVM.bookings.filter { $0.date > Date() }
            .sorted { $0.date < $1.date }
        print("Future bookings count: \(filtered.count)")
        return filtered
    }
    
    private var deleteAlertMessage: String {
        guard let booking = bookingToDelete else { return "" }
        let formattedDate = booking.date.formatted(date: .abbreviated, time: .shortened)
        return "Are you sure you want to cancel your \(booking.serviceType) appointment at \(booking.salon.name) on \(formattedDate)?"
    }
    
    var body: some View {
        NavigationView {
            Group {
                if futureBookings.isEmpty {
                    emptyAppointmentsView
                } else {
                    appointmentsList
                }
            }
            .navigationTitle("My Appointments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Cancel Appointment", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    bookingToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let booking = bookingToDelete, let id = booking.id {
                        bookingVM.deleteBooking(bookingId: id)
                    }
                    bookingToDelete = nil
                }
            } message: {
                Text(deleteAlertMessage)
            }
            .onAppear {
                print("AppointmentsView appeared")
                print("Total bookings: \(bookingVM.bookings.count)")
                print("Future bookings: \(futureBookings.count)")
            }
        }
    }
    
    private var emptyAppointmentsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No Upcoming Appointments")
                .font(.headline)
            Text("You don't have any scheduled appointments")
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    private var appointmentsList: some View {
        List {
            ForEach(futureBookings) { booking in
                appointmentRow(booking)
            }
        }
    }
    
    private func appointmentRow(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(booking.serviceType)
                    .font(.headline)
                Spacer()
                Text(booking.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(booking.salon.name)
                    .font(.subheadline)
                    .bold()
                Text(booking.salon.address ?? "No address available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                bookingToDelete = booking
                showDeleteAlert = true
            } label: {
                Label("Cancel", systemImage: "trash")
            }
        }
    }
}

// Add this new view for displaying favorite salons
struct FavoriteSalonsView: View {
    @EnvironmentObject var bookingVM: BookingViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if bookingVM.bookings.isEmpty {
                    emptyFavoritesView
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favorite Salons")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var emptyFavoritesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No Favorite Salons Yet")
                .font(.headline)
            Text("Your favorite salons will appear here based on your booking history")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var favoritesList: some View {
        List {
            ForEach(bookingVM.getTopFavoriteSalons(), id: \.salon.id) { favorite in
                favoriteSalonRow(favorite)
            }
        }
    }
    
    private func favoriteSalonRow(_ favorite: (salon: Salon, count: Int)) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(favorite.salon.name)
                    .font(.headline)
                Spacer()
                Text("\(favorite.count) visits")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(favorite.salon.address ?? "No address available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if let rating = favorite.salon.rating {
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                        Text(String(format: "%.1f", rating))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
