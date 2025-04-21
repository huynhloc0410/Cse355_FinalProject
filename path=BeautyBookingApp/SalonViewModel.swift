import Foundation
import MapKit
import CoreLocation
import SwiftUI

// MARK: - Models
struct Salon: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let description: String
    let photoURL: URL?
    let coordinate: CLLocationCoordinate2D
    let rating: Double?
}

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

// MARK: - ViewModel
class SalonViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
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
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .restricted, .denied:
            errorMessage = "Location permission is denied."
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLatitude = location.coordinate.latitude
        currentLongitude = location.coordinate.longitude
        
        fetchNearbySalons(latitude: currentLatitude!, longitude: currentLongitude!)
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Failed to get location: \(error.localizedDescription)"
    }
    
    func fetchNearbySalons(latitude: Double, longitude: Double) {
        isLoading = true
        
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
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
                    self?.salons = result.results.map { place in
                        let photoReference = place.photos?.first?.photoReference
                        let photoURL = self?.getPhotoURL(photoReference: photoReference)
                        
                        return Salon(
                            name: place.name,
                            location: place.vicinity,
                            description: "Rating: \(place.rating ?? 0.0)",
                            photoURL: photoURL,
                            coordinate: CLLocationCoordinate2D(
                                latitude: place.geometry.location.lat,
                                longitude: place.geometry.location.lng
                            ),
                            rating: place.rating
                        )
                    }
                } catch {
                    self?.errorMessage = "Failed to parse data"
                }
            }
        }.resume()
    }
    
    private func getPhotoURL(photoReference: String?) -> URL? {
        guard let reference = photoReference else { return nil }
        
        let baseURL = "https://maps.googleapis.com/maps/api/place/photo"
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "maxwidth", value: "400"),
            URLQueryItem(name: "photo_reference", value: reference),
            URLQueryItem(name: "key", value: googleAPIKey)
        ]
        return components.url
    }
} 