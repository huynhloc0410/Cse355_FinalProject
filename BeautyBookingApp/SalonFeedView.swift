//
//  SalonFeedView.swift
//  BeautyBookingApp
//
//  Created by huynh loc on 3/30/25.
//


import SwiftUI
import CoreLocation

struct SalonFeedView: View {
    @StateObject var salonVM = SalonViewModel()
    @EnvironmentObject var bookingVM: BookingViewModel
    @State private var searchText = ""
    
    var filteredSalons: [Salon] {
        if searchText.isEmpty {
            return salonVM.salons
        } else {
            return salonVM.salons.filter { salon in
                salon.name.localizedCaseInsensitiveContains(searchText) ||
                salon.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search salons...", text: $searchText)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if salonVM.isLoading {
                    ProgressView("Finding salons near you...")
                        .padding()
                } else {
                    // Salons List
                    LazyVStack(spacing: 16) {
                        ForEach(filteredSalons) { salon in
                            NavigationLink(destination: SalonDetailView(salon: salon)
                                .environmentObject(bookingVM)) {
                                SalonCard(salon: salon)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Nearby Salons")
    }
}

// Salon Card View
struct SalonCard: View {
    let salon: Salon
    @StateObject private var imageLoader = ImageLoader()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Salon Image
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
            } else {
                Image(salon.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Salon Name
                Text(salon.name)
                    .font(.title3)
                    .fontWeight(.bold)
                
                // Location
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.gray)
                    Text(salon.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Rating
                if let rating = salon.rating {
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
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear {
            if let photoReference = salon.photoReference {
                imageLoader.loadImage(from: photoReference)
            }
        }
    }
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private let salonVM = SalonViewModel()
    
    func loadImage(from photoReference: String) {
        salonVM.fetchSalonPhoto(photoReference: photoReference) { [weak self] image in
            self?.image = image
        }
    }
}

// Error View
struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Button(action: retryAction) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        SalonFeedView()
    }
}
