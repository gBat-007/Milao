import SwiftUI
struct PlansTab: View {
    @Binding var event: Event
    @Binding var presentAddLocSheet: Bool
    var body: some View {
        NavigationStack{
            VStack {
                List(event.plan.locations.indices, id: \.self) { index in
                    HStack {
                        Text(event.plan.locations[index].ofPlace.emoji)
                            .font(.largeTitle)
                            .foregroundColor(.accentColor)
                        VStack{
                            Text(event.plan.locations[index].name)
                                .fontDesign(.rounded)
                                .fontWeight(.medium)
                            Text(event.plan.locations[index].ofPlace.name.trimmingCharacters(in: .whitespacesAndNewlines))
                                .fontDesign(.default)
                                .fontWeight(.ultraLight)
                            Text("Coordinates: \(event.plan.locations[index].coordinate.latitude),\(event.plan.locations[index].coordinate.longitude)")
                                .fontDesign(.default)
                                .fontWeight(.ultraLight)
                        }
                        .padding()
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
            }
            .sheet(isPresented: $presentAddLocSheet) {
                if event.places.count > event.plan.locations.count {
                    AddLocationView(event: $event)
                } else {
                    Text("Please add more places so you can add more locations to your event plan.")
                        .font(.title)
                        .bold()
                        .fontDesign(.rounded)
                        .onTapGesture {
                            presentAddLocSheet = false
                        }
                }
            }
        }
    }
}
