//
//  ProfileView.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2026-05-12.
//

import FirebaseAuth
import GoogleSignIn
import SwiftUI


// MARK: - ProfileView

struct ProfileView: View {
    @EnvironmentObject var userAuth: UserAuth
    @EnvironmentObject var favorites: FavoritesStore

    private var firebaseUser: FirebaseAuth.User? { Auth.auth().currentUser }
    private var googleProfile: GIDProfileData? { GIDSignIn.sharedInstance.currentUser?.profile }
    private var isAnonymous: Bool { firebaseUser?.isAnonymous == true }

    private var displayName: String {
        isAnonymous ? "Gäst" : (firebaseUser?.displayName ?? googleProfile?.name ?? "Användare")
    }

    private var email: String? {
        isAnonymous ? nil : (firebaseUser?.email ?? googleProfile?.email)
    }

    private var photoURL: URL? {
        isAnonymous ? nil : (firebaseUser?.photoURL ?? googleProfile?.imageURL(withDimension: 128))
    }

    private var initials: String {
        isAnonymous ? "G" : {
            let letters = displayName.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
            return letters.isEmpty ? "?" : letters
        }()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        avatarView
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName)
                                .font(.headline)
                            if let email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Statistik") {
                    HStack {
                        Label("Sparade avsnitt", systemImage: "heart.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(favorites.favorites.count)")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Om") {
                    Text("Innehåll från Sveriges Radio. Appen är inte officiell och har ingen koppling till Sveriges Radio.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button(role: .destructive) {
                        userAuth.signOut()
                    } label: {
                        Label("Logga ut", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let photoURL {
            AsyncImage(url: photoURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                initialsCircle
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())
        } else {
            initialsCircle
        }
    }

    private var initialsCircle: some View {
        Text(initials)
            .font(.title2).bold()
            .foregroundColor(.white)
            .frame(width: 64, height: 64)
            .background(Color.accentColor)
            .clipShape(Circle())
    }
}
