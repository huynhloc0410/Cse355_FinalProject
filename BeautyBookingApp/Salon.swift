//
//  Salon.swift
//  BeautyBookingApp
//
//  Created by huynh loc on 3/30/25.
//


import Foundation
import MapKit

struct Salon: Identifiable {
    let id: String
    let name: String
    let location: String
    let description: String
    let imageName: String
    let coordinate: CLLocationCoordinate2D
    let photoReference: String?
    let address: String?
    
    // Optional additional properties
    var rating: Double?
    var openNow: Bool?
    var phoneNumber: String?
    
    // Basic initializer for essential data
    init(id: String, name: String, location: String, description: String, imageName: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.location = location
        self.description = description
        self.imageName = imageName
        self.coordinate = coordinate
        self.photoReference = nil
        self.address = nil
    }
    
    // Full initializer with all properties
    init(id: String, name: String, location: String, description: String, imageName: String, coordinate: CLLocationCoordinate2D, photoReference: String?, address: String?, rating: Double? = nil, openNow: Bool? = nil, phoneNumber: String? = nil) {
        self.id = id
        self.name = name
        self.location = location
        self.description = description
        self.imageName = imageName
        self.coordinate = coordinate
        self.photoReference = photoReference
        self.address = address
        self.rating = rating
        self.openNow = openNow
        self.phoneNumber = phoneNumber
    }
}
