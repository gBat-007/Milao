import SwiftUI
import MapKit
internal import Combine

struct OnboardingView: View {
    @State private var name = ""
    @State private var searchText = ""
    @State private var selectedPlaceID: String? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @StateObject private var completerDelegate = SearchCompleterDelegate()
    private let searchCompleter = MKLocalSearchCompleter()
    
    var onComplete: (Member) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Welcome!")) {
                    TextField("Your Name", text: $name)
                    
                    Button(action: {}){
                        Text("Sign in with Google")
                            .foregroundColor(colorScheme = .dark ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(alignment: .leading) {
                                Image("Google")
                                    .frame(width: 30, alignment: .center)
                            }
                    }
                    .buttonStyle(.bordered)
                }
                

                Section(header: Text("Search Your Location")) {
                    TextField("Enter Address", text: $searchText)
                        .onChange(of: searchText) {
                            searchCompleter.queryFragment = searchText
                        }
                    
                    if !completerDelegate.results.isEmpty {
                        List {
                            ForEach(completerDelegate.results, id: \.self) { result in
                                Button(action: {
                                    searchText = result.title + ", " + result.subtitle
                                    fetchPlaceID(for: result) { placeID in
                                        selectedPlaceID = placeID
                                    }
                                }) {
                                    VStack(alignment: .leading) {
                                        Text(result.title)
                                            .font(.headline)
                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Set Up Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let member = Member(name: name, locationPlaceID: selectedPlaceID ?? "")
                        if selectedPlaceID != "" {
                            onComplete(member)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || selectedPlaceID == nil)
                }
            }
            .onAppear {
                searchCompleter.resultTypes = .address
                searchCompleter.delegate = completerDelegate
            }
        }
    }

    // Use coordinate as a "fake place ID"
    private func fetchPlaceID(for completion: MKLocalSearchCompletion, completionHandler: @escaping (String?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.location.coordinate else {
                completionHandler(nil)
                return
            }

            // Use coordinate string as a placeholder for placeID
            completionHandler("\(coordinate.latitude),\(coordinate.longitude)")
        }
    }
}
