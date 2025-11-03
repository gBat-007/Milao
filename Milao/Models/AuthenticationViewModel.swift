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
internal import Combine

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated
}

enum AuthenticationFlow {
    case login
    case signup
}

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var flow: AuthenticationFlow = .login
    
    @Published var isValid: Bool = false
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var user: User?
    @Published var errorMessage: String = ""
    @Published var displayName: String = ""
}

extension AuthenticationViewModel {
//    func signOut
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
            return true
        } catch {
            print(error.localizedDescription)
            errorMessage = error.localizedDescription
            return false
        }
        return false
    }
}
