import Foundation
import FirebaseFirestore
import UserNotifications

class BookingViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var errorMessage: String?
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    deinit {
        listener?.remove()
    }
    
    func saveBooking(booking: Booking) {
        do {
            let _ = try db.collection("bookings").addDocument(data: booking.dictionary)
            print("Booking saved successfully")
        } catch {
            print("Error saving booking: \(error)")
            errorMessage = "Failed to save booking. Please try again."
        }
    }
    
    func fetchUserBookings(userId: String) {
        print("Fetching bookings for user: \(userId)")
        
        // Remove existing listener if any
        listener?.remove()
        
        listener = db.collection("bookings")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching bookings: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to load bookings. Please check your internet connection."
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                print("Found \(documents.count) bookings")
                self?.bookings = documents.compactMap { document in
                    if let booking = Booking(document: document) {
                        print("Booking loaded: \(booking.serviceType) at \(booking.salon.name)")
                        return booking
                    }
                    return nil
                }
                
                // Clear any previous error message
                self?.errorMessage = nil
                
                // Schedule notifications for upcoming bookings
                self?.scheduleNotifications()
            }
    }
    
    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        
        // Request permission if not already granted
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                for booking in self.bookings {
                    // Only schedule if notification hasn't been sent yet
                    if !booking.notificationSent {
                        let content = UNMutableNotificationContent()
                        content.title = "Upcoming Appointment"
                        content.body = "You have a \(booking.serviceType) appointment at \(booking.salon.name) in 2 hours"
                        content.sound = .default
                        
                        // Calculate trigger time (2 hours before appointment)
                        let triggerDate = Calendar.current.date(byAdding: .hour, value: -2, to: booking.date)!
                        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                        
                        let request = UNNotificationRequest(identifier: booking.id ?? UUID().uuidString,
                                                         content: content,
                                                         trigger: trigger)
                        
                        center.add(request) { error in
                            if let error = error {
                                print("Error scheduling notification: \(error)")
                            } else {
                                // Mark notification as sent in Firebase
                                self.markNotificationAsSent(bookingId: booking.id ?? "")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func markNotificationAsSent(bookingId: String) {
        db.collection("bookings").document(bookingId).updateData([
            "notificationSent": true
        ])
    }
    
    func deleteBooking(bookingId: String) {
        print("Deleting booking: \(bookingId)")
        db.collection("bookings").document(bookingId).delete { [weak self] error in
            if let error = error {
                print("Error deleting booking: \(error)")
                self?.errorMessage = "Failed to delete booking. Please try again."
            } else {
                print("Booking deleted successfully")
            }
        }
    }
    
    func getTopFavoriteSalons() -> [(salon: Salon, count: Int)] {
        // Group bookings by salon and count occurrences
        let salonCounts = bookings.reduce(into: [String: (salon: Salon, count: Int)]()) { result, booking in
            let salonId = booking.salon.id
            if let existing = result[salonId] {
                result[salonId] = (salon: existing.salon, count: existing.count + 1)
            } else {
                result[salonId] = (salon: booking.salon, count: 1)
            }
        }
        
        // Sort by count and take top 5
        return salonCounts.values
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }
} 