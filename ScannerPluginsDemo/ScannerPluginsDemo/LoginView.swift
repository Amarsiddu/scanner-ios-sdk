import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject var auth: AuthManager
    
    @State private var identifier = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showSignup = false
    
    var body: some View {
        
        ZStack {
            
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Customer Login")
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)
                
                VStack(spacing: 16) {
                    
                    TextField("Email / Phone / Username", text: $identifier)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                // LOGIN BUTTON
                Button {
                    
                    Task {
                        
                        let success = await auth.login(
                            identifier: identifier,
                            password: password
                        )
                        
                        if !success {
                            errorMessage = "Invalid credentials"
                        }
                    }
                    
                } label: {
                    
                    Text("Login")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button("Create Account") {
                    showSignup = true
                }
                .foregroundColor(.blue)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showSignup) {
            SignupView()
                .environmentObject(auth)
        }
    }
}
