//
//  SalonDetailView.swift
//  BeautyBookingApp
//
//  Created by huynh loc on 3/30/25.
//


import SwiftUI
import MapKit

struct SalonDetailView: View {
    let salon: Salon
    @StateObject private var imageLoader = ImageLoader()
    @State private var region: MKCoordinateRegion
    @EnvironmentObject var bookingVM: BookingViewModel

    init(salon: Salon) {
        self.salon = salon
        _region = State(initialValue: MKCoordinateRegion(
            center: salon.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                if let image = imageLoader.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                } else {
                    Image(salon.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
                Text(salon.name).font(.title).bold()
                Text(salon.description).padding()
                Text("Latitude: \(salon.coordinate.latitude)")
                Text("Longitude: \(salon.coordinate.longitude)")
                Map(coordinateRegion: $region, annotationItems: [salon]) { item in
                    MapMarker(coordinate: item.coordinate, tint: .blue)
                }
                .frame(height: 250)
                NavigationLink("Book Now", destination: BookingView(salon: salon)
                    .environmentObject(bookingVM))
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onAppear {
            if let photoReference = salon.photoReference {
                imageLoader.loadImage(from: photoReference)
            }
        }
    }
}