
import SwiftUI
import UIKit
import Firebase
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct MilaoApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                AuthenticatedView {
                    Image("LSIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .padding(4)
                    Text("Welcome to Milao!")
                        .fontDesign(.rounded)
                        .fontWeight(.bold)
                    Text("Please sign in via Google or Apple.")
                } content: {
                    ContentView()
                }
            }
        }
    }
}
