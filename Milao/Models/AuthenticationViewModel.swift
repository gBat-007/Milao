//
//  AuthenticationViewModel.swift
//  Milao
//
//  Created by Gautam Bansal on 03/11/25.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import FirebaseDatabase
internal import Combine

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

enum AuthenticationFlow {
    case login
    case signUp
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var flow: AuthenticationFlow = .login
    
    @Published var isValid: Bool = false
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var user: User?
    @Published var errorMessage: String = ""
    @Published var displayName: String = ""
    
    init() {
        registerAuthStateHandler()
    }
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    func registerAuthStateHandler(){
        if authStateHandle == nil {
            authStateHandle = Auth.auth().addStateDidChangeListener { auth, user in
                self.user = user
                self.authenticationState = user == nil ? .unauthenticated : .authenticated
                self.displayName = user?.displayName ?? "(unknown)"
            }
        }
    }
    
    
    private func wait() async {
        do {
            print("Wait")
            try await Task.sleep(nanoseconds: 1_000_000_000)
            print("Done")
        }
        catch { }
    }
    
    func reset(){
        flow = .login
    }
}

func removeID(_ id: String, from parentRef: DatabaseReference) {
    parentRef.getData { error, snapshot in
        guard error == nil else { return }

        // Read as array (Firebase will convert 0,1,2,… keys back to [String])
        var arr = snapshot?.value as? [String] ?? []

        // Remove the target ID
        arr.removeAll { $0 == id }

        // Write the updated array back
        parentRef.setValue(arr)
    }
}

extension AuthenticationViewModel {
    func signOut(){
        do {
            UserDefaults.standard.removeObject(forKey: "userID")
            UserDefaults.standard.removeObject(forKey: "memberLocation")
            try Auth.auth().signOut()
        } catch {
            print(error)
            errorMessage = error.localizedDescription
        }
    }
    func deleteAccount() async -> Bool {
        do {
            Task {
                let ref = Database.database().reference()
                ref.child("users").child(user?.uid ?? "").child("eventIDs").getData { error, snapshot in
                    guard error == nil else { return }
                    
                    var arr = snapshot?.value as? [String] ?? []
                    
                    for eventId in arr {
                        removeID(self.user?.uid ?? "", from: ref.child("events").child(eventId).child("memberIDs"))
                    }
                }
                try await ref.child("users").child(user?.uid ?? "").removeValue()
                try await user?.delete()
                UserDefaults.standard.removeObject(forKey: "userID")
                UserDefaults.standard.removeObject(forKey: "memberLocation")
            }
            try Auth.auth().signOut()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

enum AuthenticationError: Error {
    case tokenError(message: String)
}

extension AuthenticationViewModel {
    func signInWithGoogle() async -> Bool {
        guard let clientID = FirebaseApp.app()?.options.clientID else{
            fatalError("No client ID found in Firebase configuration")
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = windowScene.windows.first, let rootViewController = window.rootViewController else {
            print("There is no root view controller")
            return false
        }
        do {
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = userAuthentication.user
            guard let idToken = user.idToken else {
                throw AuthenticationError.tokenError(message: "ID token missing")
            }
            let accessToken = user.accessToken
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
            let result = try await Auth.auth().signIn(with: credential)
            let firebaseUser = result.user
            print("User \(firebaseUser.uid) signed in with email \(firebaseUser.email ?? "unknown")")
            return true
        } catch {
            print(error.localizedDescription)
            errorMessage = error.localizedDescription
            return false
        }
    }
}
