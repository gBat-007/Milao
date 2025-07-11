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
        NavigationView {
            TabView {
                Tab("Members", systemImage: "person.3.fill"){
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
                Tab("Locations", systemImage: "mappin.and.ellipse"){
                    VStack {
                        Text("Locations")
                            .bold()
                            .font(.largeTitle)
                            .padding()
                        LocationsView(locations: event.locations)
                    }
                }
                Tab("Plans", systemImage: "map"){
                    VStack {
                        Text("Plans")
                            .bold()
                            .font(.largeTitle)
                    }

                }
                
                Tab("Settings", systemImage: "gear"){
                    VStack {
                        Text("Settings")
                            .bold()
                            .font(.largeTitle)

                        Text("dog")
                    }
                    .padding()
                }
            }
            .navigationTitle($event.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
