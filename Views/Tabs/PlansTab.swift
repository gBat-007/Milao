import SwiftUI
struct PlansTab: View {
    @Binding var event: Event
    @Binding var presentAddPlanSheet: Bool
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
            .sheet(isPresented: $presentAddPlanSheet) {
                Text("Add a Plan Here")
            }
        }
    }
}
