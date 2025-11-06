import SwiftUI

extension AuthenticatedView where Unauthenticated == EmptyView {
  init(@ViewBuilder content: @escaping () -> Content) {
    self.unauthenticated = nil
    self.content = content
  }
}

struct AuthenticatedView<Content, Unauthenticated>: View where Content: View, Unauthenticated: View {
  @StateObject private var viewModel = AuthenticationViewModel()
  @State private var presentingLoginScreen = false
  @State private var presentingProfileScreen = false

  var unauthenticated: Unauthenticated?
  @ViewBuilder var content: () -> Content

  public init(unauthenticated: Unauthenticated?, @ViewBuilder content: @escaping () -> Content) {
    self.unauthenticated = unauthenticated
    self.content = content
  }

  public init(@ViewBuilder unauthenticated: @escaping () -> Unauthenticated, @ViewBuilder content: @escaping () -> Content) {
    self.unauthenticated = unauthenticated()
    self.content = content
  }


  var body: some View {
    switch viewModel.authenticationState {
    case .unauthenticated, .authenticating:
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color("AccentColor"),Color("AccentSecondary")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.7)
                .ignoresSafeArea()
            VStack {
              if let unauthenticated {
                unauthenticated
              }
              else {
                Text("You're not logged in.")
              }
                AuthenticationView()
                  .environmentObject(viewModel)
            }
        }
    case .authenticated:
      VStack {
        content()
         .environmentObject(viewModel)
      }
    }
  }
}
