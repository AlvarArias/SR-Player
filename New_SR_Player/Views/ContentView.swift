//
//  ContentView.swift
//  New_SR_Player
//
//  Created by Alvar Arias on 2023-12-15.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var userAuth: UserAuth

    var body: some View {
        //HomeView()
        LoginView(loginModel: LoginModel())
            .bannerOverlay()
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(UserAuth())
    }
}

