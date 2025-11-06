import SwiftUI
internal import Combine

struct AuthenticationView: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    
    var body: some View {
        VStack {
            if viewModel.flow == .login {
                LoginView()
                    .environmentObject(viewModel)
            }
        }
    }
}
