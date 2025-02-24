//
//  ContentView.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appController = AppController()

    var body: some View {
        VStack {
            Text("Location Logger Running")
                .font(.title)
                .padding()

            Button("Start Tracking") {
                appController.startApp()
            }
            .padding()
        }
        .onAppear {
            appController.startApp() // Ensure tracking starts when the view appears
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


#Preview {
    ContentView()
}
