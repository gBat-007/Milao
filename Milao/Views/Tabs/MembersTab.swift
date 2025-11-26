//
//  MembersTab.swift
//  Milao
//
//  Created by Gautam Bansal on 13/07/25.
//

import SwiftUI

import MapKit
import CoreLocation
import FirebaseAuth

struct MembersTab: View {
    @Binding var event: Event
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @Binding var presentAddMemberSheet: Bool
    let inviteCode: String
    var body: some View {
        VStack {
            List {
                ForEach(event.members.indices, id: \.self) { index in
                    MemberRow(member: $event.members[index])
                        .padding(.vertical, 4)
                        .bold(event.members[index].id == viewModel.user?.uid)
                }
            }
            .listStyle(.insetGrouped)
        }
        .sheet(isPresented: $presentAddMemberSheet) {
            AddMemberView(inviteCode: inviteCode)
                .presentationDetents([.fraction(0.35)])
        }
    }
}



struct MemberRow: View {
    @Binding var member: Member
    @State var memberLocation: String = ""
    var body: some View {
        VStack(spacing: 30) {
            HStack(alignment: .top, spacing: 16) {
                AsyncImage(url: URL(string: member.profilePhotoURL!)){ image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(member.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(memberLocation)
//                    HStack(spacing: 12) {
//                        Label("\(event.membersNum)", systemImage: "person.3.fill")
//                            .foregroundColor(.secondary)
//                            .font(.subheadline)
//                        
//                        Label("\(event.locationsNum)", systemImage: "mappin.and.ellipse")
//                            .foregroundColor(.secondary)
//                            .font(.subheadline)
//                    }
                }
                Spacer()
            }
            .padding(10)
            .cornerRadius(12)
        }
        .task(id: member.coordinate?.latitude) { // task re-runs when `member.id` changes
            getReverseGeocode(coord: member.coordinate ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)) { place in
                memberLocation = place ?? "Unknown Location"
            }
        }
        .onChange(of: member.coordinate?.longitude) {
            getReverseGeocode(coord: member.coordinate ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)) { place in
                memberLocation = place ?? "Unknown Location"
            }
        }
    }
}

struct AddMemberView: View {
    @Environment(\.dismiss) var dismiss

    let inviteCode: String
    
    var body: some View {
        NavigationView {
            Form {
                HStack {
                    Text("Invite Code:")
                        .bold()
                        .fontDesign(.rounded)
                    Spacer()
                    InviteCodeView(inviteCode: inviteCode)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
//                        let newMember = Member(name: name, email: email)
//                        onAdd(newMember)
                        dismiss()
                    }
                }
            }
        }
    }
}
