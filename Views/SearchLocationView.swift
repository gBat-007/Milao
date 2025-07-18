//import SwiftUI
//import MapKit
//
//struct SearchLocationView: View {
//    @Environment(\.dismiss) private var dismiss
//    @State private var searchText = ""
//    @State private var searchResults: [MKMapItem] = []
//    @State private var isSearching = false
//    
//    let onSelect: (MKMapItem) -> Void
//
//    var body: some View {
//        NavigationView {
//            List {
//                if isSearching {
//                    ProgressView()
//                } else {
//                    ForEach(searchResults, id: \.self) { item in
//                        Button {
//                            onSelect(item)
//                            dismiss()
//                        } label: {
//                            VStack(alignment: .leading) {
//                                Text(item.name ?? "Unnamed")
//                                    .font(.headline)
//                                if let address = item.placemark.title {
//                                    Text(address)
//                                        .font(.subheadline)
//                                        .foregroundColor(.secondary)
//                                }
//                            }
//                            .padding(.vertical, 4)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Search")
//            .searchable(text: $searchText, prompt: "Enter a place or address")
//            .onChange(of: searchText) { newText in
//                Task {
//                    await performSearch()
//                }
//            }
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancel") {
//                        dismiss()
//                    }
//                }
//            }
//        }
//    }
//
//    func performSearch() async {
//        guard !searchText.isEmpty else {
//            searchResults = []
//            return
//        }
//
//        isSearching = true
//        defer { isSearching = false }
//
//        let request = MKLocalSearch.Request()
//        request.naturalLanguageQuery = searchText
//        request.resultTypes = [.pointOfInterest, .address]
//
//        let search = MKLocalSearch(request: request)
//        do {
//            let response = try await search.start()
//            searchResults = response.mapItems
//        } catch {
//            print("Search failed: \(error)")
//            searchResults = []
//        }
//    }
//}
