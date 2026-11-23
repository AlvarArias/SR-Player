//
//  LoginView.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2024-04-17.
//

import GoogleSignIn
import GoogleSignInSwift
import SwiftUI
import FirebaseAuth


struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var userAuth: UserAuth
    var loginModel: LoginModel
    

    var body: some View {
        NavigationView {
            VStack {
                if userAuth.isSignedIn {
                    HomeView()
                } else {
                    VStack {
                        Text("Sign In")
                            .font(.title)
                            .padding()
                        
                        
                        TextField("", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .overlay(
                                    HStack {
                                        if email.isEmpty {
                                                         Label("Email", systemImage: "envelope")
                                                            .foregroundColor(.gray)
                                                    }
                                        Spacer()
                                    }
                                    .padding()
                                )
                            
                        SecureField("", text: $password)
                            .keyboardType(.emailAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .overlay(
                                    HStack {
                                        if email.isEmpty {
                                                         Label("Password", systemImage: "lock")
                                                            .foregroundColor(.gray)
                                                    }
                                        Spacer()
                                    }
                                   
                                )
                        
                        Text("Forgot Password?")
                            .font(.caption)
                            .padding()
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                      
                        
                        Button(action: {
                            loginModel.signInWithEmail(email: email, password: password, userAuth: userAuth)
                            
                        }) {
                            Text("Sign In")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .background(Color.blue)
                        .cornerRadius(5)
                        
                        GoogleSignInButton {
                            loginModel.signInWithGoogle(userAuth: userAuth)
                        }
                        .frame(height: 50)
                        .padding(.top)

                        Button {
                            loginModel.signInAnonymously(userAuth: userAuth)
                        } label: {
                            Text("Fortsätt som gäst")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }

                    Spacer()
                    }
                }
            }
            .padding()
            .cornerRadius(10)
        }
        
    }
    
    
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(loginModel: LoginModel())
            .environmentObject(UserAuth())
    }
}

