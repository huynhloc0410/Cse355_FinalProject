//
//  BookingView.swift
//  BeautyBookingApp
//
//  Created by huynh loc on 3/30/25.
//


import SwiftUI
import FirebaseAuth

struct BookingView: View {
    let salon: Salon
    @State private var selectedService = "Hair"
    @State private var date = Date()
    @State private var showSuccessAlert = false
    @State private var showFailureAlert = false
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var bookingVM: BookingViewModel
    @Environment(\.dismiss) var dismiss

    var services = ["Hair", "Nails", "Skin"]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Service Type")) {
                    Picker("Service", selection: $selectedService) {
                        ForEach(services, id: \.self) { service in
                            Text(service)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Date & Time")) {
                    DatePicker("Select Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section {
                    Button("Confirm Booking") {
                        if date < Date() {
                            showFailureAlert = true
                        } else if let userId = authVM.currentUser?.id {
                            let booking = Booking(
                                serviceType: selectedService,
                                date: date,
                                salon: salon,
                                userId: userId
                            )
                            bookingVM.saveBooking(booking: booking)
                            showSuccessAlert = true
                        }
                    }
                }
            }
            .navigationTitle("Book Service")
            .alert("Booking Successful", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your booking has been confirmed!")
            }
            .alert("Booking Failed", isPresented: $showFailureAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You cannot book a date in the past. Please select a future date.")
            }
        }
    }
}