//
//  EventsView.swift
//  Milao
//
//  Created by Gautam Bansal on 11/07/25.
//
import SwiftUI
import MapKit

struct EventsView: View {
    @Binding var event: Event
    var body: some View {
        NavigationStack {
            TabView {
                Group {
                    VStack {
                        Text("Members")
                            .bold()
                            .font(.largeTitle)
                        List($event.members) { $member in
                            HStack {
                                Image(systemName: "person.fill")
                                VStack(alignment: .leading) {
                                    Text(member.name)
                                        .bold()
                                        .fontDesign(.rounded)
                                    Text(member.email)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .tabItem {
                    Label("Members", systemImage: "person.3.fill")
                }
                VStack {
                    Text("Locations")
                        .bold()
                        .font(.largeTitle)
                        .padding()

                    Map(
                        coordinateRegion: .constant(MKCoordinateRegion(
                            center: event.coordinate.clLocation,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )),
                        annotationItems: [event]
                    ) { event in
                        Marker(coordinate: event.coordinate.clLocation, tint: .red)
                    }
                    .frame(height: 300)
                    .cornerRadius(10)
                    .padding()
                }
                .tabItem {
                    Label("Locations", systemImage: "mappin.and.ellipse")
                }

                VStack {
                    Text("Plans")
                        .bold()
                        .font(.largeTitle)
                }
                .tabItem {
                    Label("Plans", systemImage: "map")
                }

                VStack {
                    Text("Settings")
                        .bold()
                        .font(.largeTitle)

                    Text("dog")
                }
                .padding()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle($event.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
