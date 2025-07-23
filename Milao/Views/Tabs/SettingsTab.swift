import SwiftUI

struct SettingsTab: View {
    @Binding var event: Event
    @State var primaryClr: Color = Color.blue
    @State var secondaryClr: Color = Color.green
    
    var body: some View {
        
        Form {
            
            Section(header: Text("Appearance")) {
                ColorPicker("Primary Color", selection: $primaryClr)
                ColorPicker("Secondary Color", selection: $secondaryClr)
            }
            .onChange(of: primaryClr) {
                event.bgColor1 = CodableColor(color: primaryClr)
                event.saveToDatabase()
            }
            .onChange(of: secondaryClr) {
                event.bgColor2 = CodableColor(color: secondaryClr)
                event.saveToDatabase()
            }

            Section(header: Text("Event Info")) {
                HStack{
                    Text("Emoji ")
                        .fontDesign(.rounded)
                    EmojiKeyboardButton(emoji: $event.emoji)
                        .frame(width: 50, height: 50)
                        .overlay(RoundedRectangle(cornerRadius: 45).stroke(Color.gray.opacity(0.4)).blur(radius: 20.0))
                }
                .onChange(of: event.emoji) {
                    event.saveToDatabase()
                }

                DatePicker("Event Date & Time", selection: $event.eventDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .onChange(of: event.eventDate) {
                        event.saveToDatabase()
                    }
            }
            
        }
        .navigationTitle("Settings")
        .onAppear {
            primaryClr = event.bgColor1.color
            secondaryClr = event.bgColor2.color
        }

    }
}
