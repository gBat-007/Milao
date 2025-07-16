import SwiftUI

struct SettingsTab: View {
    @Binding var primaryColor: CodableColor
    @Binding var secondaryColor: CodableColor
    @State var primaryClr: Color = Color.blue
    @State var secondaryClr: Color = Color.green
    @Binding var eventEmoji: String
    @Binding var eventDate: Date
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                ColorPicker("Primary Color", selection: $primaryClr)
                ColorPicker("Secondary Color", selection: $secondaryClr)
            }
            .onChange(of: primaryClr){
                primaryColor = CodableColor(color: primaryClr)
            }
            .onChange(of: secondaryClr){
                secondaryColor = CodableColor(color: secondaryClr)
            }

            Section(header: Text("Event Info")) {
                HStack {
                    Text("Emoji")
                    Spacer()
                    TextField("😊", text: $eventEmoji)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 50)
                }

                DatePicker("Event Date & Time", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
            }
        }
        .navigationTitle("Settings")
        .onAppear{
            primaryClr = primaryColor.color
            secondaryClr = secondaryColor.color
        }
    }
}
