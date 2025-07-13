import SwiftUI

struct PlansTab: View {
    @Binding var plans: [Plan]
    @Binding var presentAddPlanSheet: Bool
    var body: some View {
        VStack {
            List(plans.indices, id: \.self) { index in
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(.accentColor)
                    Text(plans[index].name)
                        .font(.body)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.insetGrouped)
        }
        .sheet(isPresented: $presentAddPlanSheet) {
            Text("Add a Plan Here")
        }
    }
}
