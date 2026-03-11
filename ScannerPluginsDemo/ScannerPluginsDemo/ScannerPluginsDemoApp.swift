import SwiftUI

@main
struct ScannerPluginsDemoApp: App {

    @StateObject var auth = AuthManager()

    var body: some Scene {

        WindowGroup {

            if auth.isLoggedIn {
                ContentView()
                    .environmentObject(auth)
            } else {
                LoginView()
                    .environmentObject(auth)
            }
        }
    }
}
