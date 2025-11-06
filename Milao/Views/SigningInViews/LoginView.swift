import SwiftUI
internal import Combine

struct LoginView: View {
  @EnvironmentObject var viewModel: AuthenticationViewModel
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.dismiss) var dismiss

  private func signInWithGoogle() {
    Task {
      if await viewModel.signInWithGoogle() == true {
//        var locationManager = LocationManager()
//        locationManager.requestAuthorization()
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
