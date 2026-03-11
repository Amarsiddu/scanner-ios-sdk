import SwiftUI

struct SignupView: View {
    
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    
    @State private var message = ""
    
    var body: some View {
        
        ZStack {
            
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                Text("Create Account")
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)
                
                VStack(spacing: 16) {
                    
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Phone Number", text: $phone)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .keyboardType(.phonePad)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                
                Button {
                    
                    Task {
                        await signupUser()
                    }
                    
                } label: {
                    
                    Text("Register")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Spacer()
            }
            .padding()
        }
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
    
    
    // MARK: Signup API
    
    func signupUser() async {
        
        guard let url = URL(string: "https://scanner-backend-k4ag.onrender.com/auth/signup") else {
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String:Any] = [
            "username": username,
            "email": email,
            "phone": phone,
            "password": password
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let response = try JSONDecoder().decode(SignupResponse.self, from: data)
            
            if response.success {
                
                DispatchQueue.main.async {
                    dismiss()
                }
                
            } else {
                
                DispatchQueue.main.async {
                    message = response.message ?? "Signup failed"
                }
            }
            
        } catch {
            DispatchQueue.main.async {
                message = "Network error"
            }
        }
    }
}

struct SignupResponse: Decodable {
    let success: Bool
    let message: String?
}
