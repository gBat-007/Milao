import SwiftUI
internal import Combine
import FirebaseDatabase
import FirebaseAuth

struct LoginView: View {
  @EnvironmentObject var viewModel: AuthenticationViewModel
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.dismiss) var dismiss

  private func signInWithGoogle() {
    Task {
      if await viewModel.signInWithGoogle() == true {
//        var locationManager = LocationManager()
//        locationManager.requestAuthorization()
          let ref = Database.database().reference()
          let member = Member(from: viewModel.user!)
          do {
              try await ref.child("users").child(viewModel.user!.uid).updateChildValues([
                  "id": member.id,
                  "name": member.name,
                  "locationPlaceID": member.locationPlaceID,
                  "profilePhotoURL": member.profilePhotoURL ?? ""
              ])
          } catch {
              print(error.localizedDescription)
          }
          UserDefaults.standard.set(viewModel.user!.uid, forKey: "userID")
          dismiss()
      }
    }
  }

  var body: some View {
    VStack {

      Button(action: signInWithGoogle) {
          HStack{
              Image("Google")
                  .resizable()
                  .frame(width: 30, height: 30)
                  .brightness(colorScheme == .dark ? 0 : 0.35)

              Text("Sign in with Google")
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
          }
      }
      .onTapGesture {
          viewModel.reset()
      }
      .foregroundColor(colorScheme == .dark ? .black : .white)
      .buttonStyle(.glassProminent)
    }
    .listStyle(.plain)
    .padding()
  }
}
