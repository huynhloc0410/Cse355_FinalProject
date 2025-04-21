//
//  SalonViewModel.swift
//  BeautyBookingApp
//
//  Created by huynh loc on 3/30/25.
//


import Foundation
import MapKit
import CoreLocation
import SwiftUI

class SalonViewModel: NSObject, ObservableObject,CLLocationManagerDelegate {
    @Published var salons: [Salon] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    @Published var currentLatitude: Double?
    @Published var currentLongitude: Double?
    private let locationManager = CLLocationManager()
    
    private let googleAPIKey = "AIzaSyDbJ68YKPijvGX-MXYFMtxhe4ceW1SIMDM"
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        requestLocationPermission()
        // Fetch salons immediately with a fixed location (e.g., New York City)
        // fetchNearbySalons(latitude: 40.7128, longitude: -74.0060)
        print("First catch")
    }
    
    
    //12312313
    func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        print("Status: \(CLAuthorizationStatus(rawValue: status.rawValue)!)")

        switch status {
        case .notDetermined:
            print("catch me here, 3")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .restricted, .denied:
            errorMessage = "Location permission is denied."
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        currentLatitude = location.coordinate.latitude
        currentLongitude = location.coordinate.longitude

        print("📍 Current Location: \(currentLatitude!), \(currentLongitude!)")
        
        // Fetch nearby salons using the current location
        if let lat = currentLatitude, let lon = currentLongitude {
            fetchNearbySalons(latitude: lat, longitude: lon)
        }
        
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Failed to get location: \(error.localizedDescription)"
    }

    
    
    
    
    
    
    func fetchNearbySalons(latitude: Double, longitude: Double) {
        isLoading = true
        print("🔍 Fetching salons...")

        let baseURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "location", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "radius", value: "5000"),
            URLQueryItem(name: "type", value: "beauty_salon"),
            URLQueryItem(name: "key", value: googleAPIKey)
        ]

        guard let url = urlComponents.url else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }

        print("📍 Making request to: \(url.absoluteString)")

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    print("❌ Error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    return
                }

                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }

                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📦 Response: \(jsonString)")
                }

                do {
                    let result = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
                    print("✅ Status: \(result.status)")
                    print("📊 Found \(result.results.count) salons")

                    self?.salons = result.results.map { place in
                        Salon(
                            id: UUID().uuidString,
                            name: place.name,
                            location: place.vicinity,
                            description: "Rating: \(place.rating ?? 0.0)",
                            imageName: "salon1",
                            coordinate: CLLocationCoordinate2D(
                                latitude: place.geometry.location.lat,
                                longitude: place.geometry.location.lng
                            ),
                            photoReference: place.photos?.first?.photoReference,
                            address: place.vicinity,
                            rating: place.rating
                        )
                    }
                } catch {
                    print("❌ Decoding error: \(error)")
                    self?.errorMessage = "Failed to parse data"
                }
            }
        }.resume()
    }
    
    func fetchSalonPhoto(photoReference: String, completion: @escaping (UIImage?) -> Void) {
        let baseURL = "https://maps.googleapis.com/maps/api/place/photo"
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "maxwidth", value: "400"),
            URLQueryItem(name: "photo_reference", value: photoReference),
            URLQueryItem(name: "key", value: googleAPIKey)
        ]
        
        guard let url = urlComponents.url else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}

// API Response Models
struct GooglePlacesResponse: Codable {
    let results: [Place]
    let status: String
}

struct Place: Codable {
    let name: String
    let vicinity: String
    let geometry: Geometry
    let rating: Double?
    let photos: [PlacePhoto]?
}

struct Geometry: Codable {
    let location: Location
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}

struct PlacePhoto: Codable {
    let photoReference: String
    
    enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
    }
}


