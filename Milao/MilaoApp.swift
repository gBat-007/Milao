import SwiftUI
import UIKit
import Firebase
import FirebaseCore
import FirebaseFirestore
internal import Combine

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

class AppFirestoreManager: ObservableObject {
    @Published var listeners: [ListenerRegistration] = []
    
    func startListeningToAllEvents() {
        let db = Firestore.firestore()
        let listener = db.collection("events").addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ App-wide listener error:", error)
                return
            }
            print("🔄 Events collection updated app-wide")
        }
        listeners.append(listener)
    }
    
    func stopAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    deinit {
        stopAllListeners()
    }
}

@main
struct MilaoApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var firestoreManager = AppFirestoreManager()

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
                        .environmentObject(firestoreManager)
                        .onAppear {
                            firestoreManager.startListeningToAllEvents()
                        }
                }
            }
        }
    }
}
