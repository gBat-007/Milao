//
//  EventsView.swift
//  Milao
//
//  Created by Gautam Bansal on 11/07/25.
//
import SwiftUI

struct EventsView: View {
    @Binding var event: Event
    var body: some View {
        NavigationView {
            TabView {
                Tab("Members", systemImage: "person.3.fill") {
                    Text("Members")
                        .bold()
                        .font(.largeTitle)
                    List($event.members){ $member in
                        VStack{
                            Text(member.name)
                                .bold()
                                .fontDesign(.rounded)
                            Text(member.email)
                        }
                        .padding()
                    }
                }
                Tab("Chats", systemImage: "message") {
                    VStack{
                        Text("Chats")
                            .bold()
                            .font(.largeTitle)
                        ChatsView()
                    }
                    .padding()
                    
                }
                Tab("Locations", systemImage: "mappin.and.ellipse") {
                    VStack{
                        Text("Locations")
                            .bold()
                            .font(.largeTitle)
                    }
                    
                }
                Tab("Plans", systemImage: "map") {
                    VStack{
                        Text("Plans")
                            .bold()
                            .font(.largeTitle)
                    }
                    
                }
                
                Tab("Settings", systemImage: "gear") {
                    VStack{
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
