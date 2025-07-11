//
//  ContentView.swift
//  Milao
//
//  Created by Gautam Bansal on 09/07/25.
//

import SwiftUI

struct ContentView: View {
    @State var events = myEvents
    var body: some View {
        NavigationView {
            
            List($events) { $event in
                NavigationLink(destination: EventsView(event: $event)){
                    EventRow(event: $event)
                        .padding(.vertical, 4)
                }
                
            }
            .toolbar{
                ToolbarItem(placement: .topBarLeading){
                    Button("Profile", systemImage: "person.circle"){
                        
                    }
                }
                ToolbarItem(placement: .topBarTrailing){
                    Button("Add Event", systemImage: "plus"){
                        
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("My Events")
            
        }
    }
}

struct EventRow: View {
    @Binding var event: Event
    
    var body: some View {
        VStack(spacing: 30) {
            HStack(alignment: .top, spacing: 16) {
                Text(event.emoji)
                    .font(.system(size: 36))
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        Label("\(event.membersNum)", systemImage: "person.3.fill")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        
                        Label("\(event.locationsNum)", systemImage: "mappin.and.ellipse")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
                Spacer()
            }
            .padding(10)
            .cornerRadius(12)
        }
    }
    
    #Preview {
        ContentView()
    }
}
