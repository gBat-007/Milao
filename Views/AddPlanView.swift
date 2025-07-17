//
//  AddPlanView.swift
//  Milao
//
//  Created by yash on 17/07/25.
//
import SwiftUI

struct AddLocationView: View {
    @Binding var event: Event
    var body: some View {
        NavigationStack{
            VStack {
                List(event.plan.locations.indices, id: \.self) { index in
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundColor(.accentColor)
                        Text(event.plan.locations[index].name)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}
