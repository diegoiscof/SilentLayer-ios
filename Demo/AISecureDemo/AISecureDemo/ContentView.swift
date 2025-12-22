//
//  ContentView.swift
//  AISecureDemo
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import SwiftUI
import AISecure

struct ContentView: View {

    var body: some View {
        VStack(spacing: 20) {
            Text("Test")
                .font(.headline)
            Button("Run Test") {
            }
        }
        .padding()
        .onAppear {
            // Configure logging
            AISecure.configure(logLevel: .debug)

            Task {
                do {
                    let openAI = try AISecure.openAIService(
                        projectId: "proj_1766366370544_22e1922f7e5e",
                        services: [
                            try AISecureServiceConfig(
                                provider: "openai",
                                serviceURL: "https://xifm3whdw1.execute-api.us-east-2.amazonaws.com/openai-df56eb4a4befeb88",
                                partialKey: "c2stcHJvai1mb2JLMHNXbUNFZFlVNUd6OUlXR1NyZWxSWXZaTi1ia1lzc18zbDY3aC1Gd1pPaXFiRjZ6ZjdZak1wQUZNUHA5QTlEQWdHcW1QTA=="
                            )
                        ],
                        backendURL: "https://bee-extras-intellectual-walt.trycloudflare.com"
                    )

                    let chatResponse = try await openAI.chat(messages: [
                        .init(role: "user", content: "Hello gpt")
                    ])
                    print(chatResponse.choices.first?.message.content ?? "")
                } catch let AISecureError.httpError(status, body) {
                    print("Request failed:", status)

                    // Pretty print the JSON debug info
                    if let jsonData = try? JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted]),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("DEBUG INFO:")
                        print(jsonString)
                    } else {
                        print(body)
                    }
                } catch {
                    print("Unexpected error:", error)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
