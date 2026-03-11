import SwiftUI
import Combine

class AuthManager: ObservableObject {

    @Published var isLoggedIn: Bool = false
    @Published var token: String = ""
    @Published var username: String = ""   // ✅ ADD THIS

    func login(identifier: String, password: String) async -> Bool {

        guard let url = URL(string: "https://scanner-backend-k4ag.onrender.com/auth/login") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "identifier": identifier,
            "password": password
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {

            let (data, _) = try await URLSession.shared.data(for: request)

            let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)

            if decoded.success {

                DispatchQueue.main.async {

                    self.token = decoded.token ?? ""
                    self.username = identifier      // ✅ store username
                    self.isLoggedIn = true

                    // SAVE TOKEN + USERNAME
                    UserDefaults.standard.set(self.token, forKey: "authToken")
                    UserDefaults.standard.set(self.username, forKey: "username")
                }

                return true
            }

        } catch {
            print(error)
        }

        return false
    }

    func logout() {
        isLoggedIn = false
        token = ""
        username = ""

        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "username")
    }
}

struct LoginResponse: Decodable {
    let success: Bool
    let token: String?
}
