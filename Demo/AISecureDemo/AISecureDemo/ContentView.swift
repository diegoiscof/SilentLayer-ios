//
//  ContentView.swift
//  AISecureDemo
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import SwiftUI
import AISecure

struct ContentView: View {
    
    @State private var message = "Click to test package"
    
    var body: some View {
        VStack(spacing: 20) {
            Text(message)
                .font(.headline)
            Button("Run Test") {
                message = PackageHealthCheck.status()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
