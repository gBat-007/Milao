//
//  MembersTab.swift
//  Milao
//
//  Created by Gautam Bansal on 13/07/25.
//

import SwiftUI

import SwiftUI

struct MembersTab: View {
    @Binding var members: [Member]
    @Binding var presentAddMemberSheet: Bool

    var body: some View {
        VStack {
            List($members) { $member in
                MemberRow(member: $member)
                    .padding(.vertical, 4)
            }
            .listStyle(.insetGrouped)
        }
        .sheet(isPresented: $presentAddMemberSheet) {
            AddMemberView { newMember in
                members.append(newMember)
            }
            .presentationDetents([.medium])
        }
    }
}



struct MemberRow: View {
    @Binding var member: Member
    
    var body: some View {
        VStack(spacing: 30) {
            HStack(alignment: .top, spacing: 16) {
                Text(String(member.name.prefix(1)))
                    .font(.system(size: 36))
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(member.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
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
    }
    
}

struct AddMemberView: View {
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var email = ""

    var onAdd: (Member) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Member Details")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("New Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newMember = Member(name: name, email: email)
                        onAdd(newMember)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || email.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
