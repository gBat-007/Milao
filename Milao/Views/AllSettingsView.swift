import SwiftUI
import MapKit
import Contacts
import CoreLocation
import FirebaseDatabase
import FirebaseAuth
internal import Combine
import FirebaseFirestore


//extension View {
//    func scaleEffectOnTap() -> some View {
//        self.modifier(TapScaleEffect())
//    }
//}
//struct TapScaleEffect: ViewModifier {
//    @State private var isPressed = false
//
//    func body(content: Content) -> some View {
//        content
//            .scaleEffect(isPressed ? 0.95 : 1.0)
//            .animation(.easeOut(duration: 0.15), value: isPressed)
//            .simultaneousGesture(
//                DragGesture(minimumDistance: 0)
//                    .onChanged { _ in isPressed = true }
//                    .onEnded { _ in isPressed = false }
//            )
//    }
//}


struct AllSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var events: [Event]

    @State private var tempName: String = ""
    @State private var isLiveActivityOn = false
//    @State private var tempLocation: String
//    @State private var coordinate: CLLocationCoordinate2D?
    @State private var selectedEventID: String?
    @State private var showEventPicker: Bool = false
    @State private var isUpdating = false
    @State private var message = "Loading..."
//    @State private var editLocationSheet: Bool = false
    @EnvironmentObject var viewModel: AuthenticationViewModel
//    @StateObject private var completerDelegate = SearchCompleterDelegate()
    @State var presentingConfirmationDialog = false
    @AppStorage("memberLocation") var memberLocation: String = "37.3346,-122.0090"
//    private let searchCompleter = MKLocalSearchCompleter()
//    private let geocoder = CLGeocoder()
    
    private func deleteAccount() {
        Task {
            if await viewModel.deleteAccount() == true {
                dismiss()
            }
        }
    }
    
    private func signOut() {
        viewModel.signOut()
    }
    
    func updateLocation(){
        isUpdating = true
        message = "Updating..."
        
        LocationManager.shared.requestOneTimeLocation { location in
            DispatchQueue.main.async {
                isUpdating = false
                
                guard let loc = location else {
                    message = "Unable to get location."
                    return
                }
                
                memberLocation = String("\(loc.coordinate.latitude),\(loc.coordinate.longitude)")
                
                Task {
                    let ref = Database.database().reference()
                    do {
                        try await ref.child("users")
                            .child(viewModel.user!.uid)
                            .child("locationPlaceID")
                            .setValue(String("\(loc.coordinate.latitude),\(loc.coordinate.longitude)"))
                        
                        // Option A: Notify the events owner to force refresh its observers/stream.
                        NotificationCenter.default.post(name: .memberSettingsDidChangeAffectingEvents, object: nil)
                        
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                
                Task {
                    let locationName = await resolveExactLocationName(from: stringToCoordinate(memberLocation)?.clLocation)
                    message = "Location Updated! New Location: \(locationName)"
                }
            }
        }
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Your Name") {
                    Text(viewModel.displayName)
                }
                
                Section("Manage Account") {
                    Button(role: .cancel, action: signOut){
                        Text("Sign Out")
                    }
                    Button(role: .destructive, action: {presentingConfirmationDialog.toggle()}){
                        Text("Delete Account")
                    }
                }
                .confirmationDialog("Deleting your account is permanent, and all your event data will be lost. Do you want to delete your account?", isPresented: $presentingConfirmationDialog, titleVisibility:.visible){
                    Button("Delete Account", role: .destructive, action: deleteAccount)
                    Button("Cancel", role: .cancel, action: { })
                }

                Section("Your Location") {
                    
                    Button(action: updateLocation) {
                        if isUpdating {
                            ProgressView()
                        } else {
                            Text("Update Your Location")
                        }
                    }
                    
                    Text(message)
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                
//                    Button("Edit Your Location") {
//                        editLocationSheet = true
//                    }
//
//                    .sheet(isPresented: $editLocationSheet){
//                        NavigationStack {
//                            Form {
//                                TextField("Search Location", text: $tempLocation)
//                                    .onChange(of: tempLocation) { _, newValue in
//                                        searchCompleter.queryFragment = newValue
//                                    }
//
//                                if !completerDelegate.results.isEmpty {
//                                    Section {
//                                        ForEach(completerDelegate.results, id: \.self) { result in
//                                            Button {
//                                                selectLocation(result)
//                                            } label: {
//                                                VStack(alignment: .leading) {
//                                                    Text(result.title).bold()
//                                                    if !result.subtitle.isEmpty {
//                                                        Text(result.subtitle)
//                                                            .font(.subheadline)
//                                                            .foregroundColor(.gray)
//                                                    }
//                                                }
//                                                .padding(.vertical)
//                                            }
//                                        }
//                                    }
//                                }
//
//                                if let coord = coordinate {
//                                    Map {
//                                        Marker("Your Location", coordinate: coord)
//                                    }
//                                    .frame(height: 400)
//                                    .cornerRadius(10)
//                                } else {
//                                    Text("No location selected")
//                                        .foregroundColor(.gray)
//                                }
//                            }
//                            .navigationTitle("Edit Your Location")
//                            .toolbar {
//                                ToolbarItem(placement: .confirmationAction) {
//                                    Button("Done") { editLocationSheet = false }
//                                }
//                            }
//                        }
//                    }
//
//                }
                
                Section("Live Activities") {
                    // 1. Create a sorted list of upcoming events
//                    let upcomingEvents = events
//                        .filter { $0.eventDate > Date() }
//                        .sorted(by: { $0.eventDate < $1.eventDate })

                    // 2. Picker to select an event by title
                    Picker("Choose Event", selection: $selectedEventID) {
                        ForEach(events.filter { $0.eventDate > Date() && $0.eventDate < Date().addingTimeInterval(3600) }) { event in
                            Text(event.title).tag(event.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedEventID) { newValue in
                        print("🔍 Picker selection changed. New selectedEventID: \(newValue ?? "nil")")
                    }

                    // 3. Start Button - triggers Live Activity for selected event
                    Toggle("Live Activity", isOn: $isLiveActivityOn)
                        .disabled(selectedEventID == nil)
                        .onChange(of: isLiveActivityOn) { _, newValue in
                            if newValue {
                                startLiveActivity()
                            } else {
                                stopAllActivities()
                            }
                        }

                    Button("Refresh Event") {
                        refreshEvent()
                    }
                
                }
                
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
//                        member.name = tempName
//                        if let coord = coordinate {
//                            member.locationPlaceID = tempLocation
//                            member.coordinate = coord
//                        }
                        dismiss()
                    }
//                    .disabled(tempName.isEmpty || coordinate == nil || tempLocation.isEmpty)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                Task {
                    let locationName = await resolveExactLocationName(from: stringToCoordinate(memberLocation)?.clLocation)
                    message = "Home Location: \(locationName)"
                }
            }
//            .onAppear {
//                searchCompleter.delegate = completerDelegate
//
//                    if let coord = coordinate {
//                        reverseGeocode(coord: coord)
//                    }
//            }
        }
    }
    
    private func startLiveActivity() {
        print("🚀 Start button tapped.")
        
        guard let id = selectedEventID else {
            print("❌ selectedEventID is nil.")
            isLiveActivityOn = false
            return
        }
        
        guard let event = events.first(where: { $0.id == id }) else {
            print("❌ Could not find event with id: \(id)")
            isLiveActivityOn = false
            return
        }
        
        print("✅ Found event: \(event.title) with ID: \(event.id)")
        
        // Persist the selected event ID globally
        EventManager.shared.selectedEventID = event.id
        EventManager.shared.activeLiveActivityEventID = event.id
        print("💾 Persisted active Live Activity event ID: \(event.id)")
        
        TimerManager.shared.stopAllLiveActivities()
        print("🟢 Starting new live activity for event: \(event.id)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            TimerManager.shared.startSimpleTimer(to: event.asWidgetEvent)
        }
    }

    private func stopAllActivities() {
        TimerManager.shared.stopAllLiveActivities()
        EventManager.shared.clearActiveEvent()
        isLiveActivityOn = false
        print("⛔ Stopped all live activities and cleared cached event ID.")
    }

    private func refreshEvent() {
        guard let id = EventManager.shared.activeLiveActivityEventID else {
            print("❌ No cached active Live Activity ID found.")
            return
        }
        
        guard let event = events.first(where: { $0.id == id }) else {
            print("❌ Could not find event with id: \(id)")
            return
        }
        
        print("🔄 Refreshing Live Activity for cached event: \(event.title) (\(event.id))")
        print("The cached event info is \(event.title) \(event.emoji) (\(event.id))")
        TimerManager.shared.updateSimpleTimer(to: event.newWidgetEvent(event: event))
    }
//
//    private func selectLocation(_ result: MKLocalSearchCompletion) {
//        let request = MKLocalSearch.Request(completion: result)
//        MKLocalSearch(request: request).start { response, _ in
//            guard let loc = response?.mapItems.first?.location else { return }
//            let coord = loc.coordinate
//            self.coordinate = coord
//            self.tempLocation = "\(result.title), \(result.subtitle)"
//            self.reverseGeocode(coord: coord)
//        }
//    }
//
//    private func reverseGeocode(coord: CLLocationCoordinate2D) {
//        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
//        geocoder.reverseGeocodeLocation(location) { placemarks, error in
//            guard let placemark = placemarks?.first else { return }
//
//            if let postalAddr = placemark.postalAddress {
//                let formatted = CNPostalAddressFormatter.string(from: postalAddr, style: .mailingAddress)
//                self.tempLocation = formatted
//            } else {
//                let parts = [
//                    placemark.name,
//                    placemark.thoroughfare,
//                    placemark.locality,
//                    placemark.administrativeArea,
//                    placemark.country
//                ]
//                self.tempLocation = parts.compactMap { $0 }.joined(separator: ", ")
//            }
//        }
//    }
}

//
//import CoreLocation
//import Contacts
//
func getReverseGeocode(coord: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
    let geocoder = CLGeocoder()
    let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)

    func finishOnMain(_ value: String?) {
        if Thread.isMainThread {
            completion(value)
        } else {
            DispatchQueue.main.async { completion(value) }
        }
    }

    func searchNearestLandmark() {
        let region = MKCoordinateRegion(center: coord,
                                        latitudinalMeters: 1000,
                                        longitudinalMeters: 1000)
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = nil // broad POI search
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let items = response?.mapItems, error == nil else {
                finishOnMain(nil)
                return
            }

            // Sort by distance to the coordinate
            let sorted = items.sorted {
                guard let l0 = $0.placemark.location?.distance(from: location),
                      let l1 = $1.placemark.location?.distance(from: location) else { return false }
                return l0 < l1
            }

            if let best = sorted.first, let title = best.name, !title.isEmpty {
                let subtitle = best.placemark.title ?? best.placemark.subtitle
                if let sub = subtitle, !sub.isEmpty {
                    finishOnMain("\(title), \(sub)")
                } else {
                    finishOnMain(title)
                }
            } else {
                finishOnMain(nil)
            }
        }
    }

    geocoder.reverseGeocodeLocation(location) { placemarks, error in
        guard let placemark = placemarks?.first, error == nil else {
            searchNearestLandmark()
            return
        }

        // If we have a postal address, prefer it.
        if let postalAddr = placemark.postalAddress {
            let formatted = CNPostalAddressFormatter.string(from: postalAddr, style: .mailingAddress)
            finishOnMain(formatted)
            return
        }

        // Extract components we care about
        let name = placemark.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let street = placemark.thoroughfare?.trimmingCharacters(in: .whitespacesAndNewlines)
        let subStreet = placemark.subThoroughfare?.trimmingCharacters(in: .whitespacesAndNewlines)
        let locality = placemark.locality?.trimmingCharacters(in: .whitespacesAndNewlines)
        let admin = placemark.administrativeArea?.trimmingCharacters(in: .whitespacesAndNewlines)
        let country = placemark.country?.trimmingCharacters(in: .whitespacesAndNewlines)

        // Determine if result is only locality-level (no street/name)
        let hasStreetLevel = (street?.isEmpty == false) || (subStreet?.isEmpty == false)

        if hasStreetLevel {
            let parts = [name, street, locality, admin, country]
            let formatted = parts.compactMap { $0 }.joined(separator: ", ")
            finishOnMain(formatted.isEmpty ? nil : formatted)
        } else {
            // Only city-level: fallback to MKLocalSearch
            searchNearestLandmark()
        }
    }
}

extension Notification.Name {
    // Posted after AllSettingsView successfully writes the user's location to /users/<uid>/locationPlaceID.
    // The events owner should observe this and force-refresh its events stream (remove observers and re-attach).
    static let memberSettingsDidChangeAffectingEvents = Notification.Name("memberSettingsDidChangeAffectingEvents")
}
