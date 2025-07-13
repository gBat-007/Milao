
import SwiftUI
import UIKit
import Firebase
import FirebaseCore
import FirebaseFirestore

@main
struct MilaoApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
