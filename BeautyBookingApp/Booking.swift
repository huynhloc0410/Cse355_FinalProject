//
//  Booking.swift
//  BeautyBookingApp
//
//  Created by huynh loc on 3/30/25.
//

import Foundation
import FirebaseFirestore
import MapKit

struct Booking: Identifiable {
    var id: String?
    let serviceType: String
    let date: Date
    let salon: Salon
    let userId: String
    var notificationSent: Bool = false
    
    // Initializer for creating a new booking
    init(serviceType: String, date: Date, salon: Salon, userId: String, notificationSent: Bool = false) {
        self.serviceType = serviceType
        self.date = date
        self.salon = salon
        self.userId = userId
        self.notificationSent = notificationSent
    }
    
    // Convert Booking to dictionary for Firestore
    var dictionary: [String: Any] {
        return [
            "serviceType": serviceType,
            "date": date,
            "salon": [
                "id": salon.id,
                "name": salon.name,
                "location": salon.location,
                "description": salon.description,
                "imageName": salon.imageName,
                "coordinate": [
                    "latitude": salon.coordinate.latitude,
                    "longitude": salon.coordinate.longitude
                ],
                "photoReference": salon.photoReference as Any,
                "address": salon.address as Any,
                "rating": salon.rating as Any,
                "openNow": salon.openNow as Any,
                "phoneNumber": salon.phoneNumber as Any
            ],
            "userId": userId,
            "notificationSent": notificationSent
        ]
    }
    
    // Initialize from Firestore document
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        print("Decoding booking document: \(data)")
        
        guard let serviceType = data["serviceType"] as? String,
              let timestamp = data["date"] as? Timestamp,
              let salonData = data["salon"] as? [String: Any],
              let salonId = salonData["id"] as? String,
              let salonName = salonData["name"] as? String,
              let salonLocation = salonData["location"] as? String,
              let salonDescription = salonData["description"] as? String,
              let salonImageName = salonData["imageName"] as? String,
              let coordinateData = salonData["coordinate"] as? [String: Double],
              let latitude = coordinateData["latitude"],
              let longitude = coordinateData["longitude"] else {
            print("Failed to decode booking document: Missing required fields")
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        self.id = document.documentID
        self.serviceType = serviceType
        self.date = timestamp.dateValue()
        self.salon = Salon(
            id: salonId,
            name: salonName,
            location: salonLocation,
            description: salonDescription,
            imageName: salonImageName,
            coordinate: coordinate,
            photoReference: salonData["photoReference"] as? String,
            address: salonData["address"] as? String,
            rating: salonData["rating"] as? Double,
            openNow: salonData["openNow"] as? Bool,
            phoneNumber: salonData["phoneNumber"] as? String
        )
        self.userId = data["userId"] as? String ?? ""
        self.notificationSent = data["notificationSent"] as? Bool ?? false
        
        print("Successfully decoded booking: \(self.serviceType) at \(self.salon.name)")
    }
}
