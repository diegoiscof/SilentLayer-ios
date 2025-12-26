//
//  ContentView.swift
//  AISecureDemo
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import SwiftUI
import AISecure
import AVFoundation

func timestamp() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    let now = Date()
    let timeString = formatter.string(from: now)
    let milliseconds = Int(now.timeIntervalSince1970 * 1000) % 1000
    return "[\(timeString).\(String(format: "%03d", milliseconds))]"
}

struct ContentView: View {
    
    //For Audio
    @State private var audioPlayer: AVAudioPlayer?
    
    @State private var selectedProvider = 0
    @State private var selectedEndpoint = 0
    @State private var output = ""
    @State private var isLoading = false

    let providers = ["OpenAI", "Anthropic", "Gemini", "Grok"]

    var openAIEndpoints: [(String, () async -> Void)] {
        [
            ("Chat Completion", testOpenAIChat),
            ("Image Generation (DALL-E)", testOpenAIImage),
            ("Embeddings", testOpenAIEmbeddings),
            ("Text-to-Speech", testOpenAITTS),
            ("Content Moderation", testOpenAIModeration)
        ]
    }

    var anthropicEndpoints: [(String, () async -> Void)] {
        [
            ("Create Message", testAnthropicMessage)
        ]
    }

    var geminiEndpoints: [(String, () async -> Void)] {
        [
            ("Generate Content", testGeminiContent)
        ]
    }

    var grokEndpoints: [(String, () async -> Void)] {
        [
            ("Chat Completion", testGrokChat),
            ("Chat with Vision", testGrokVision)
        ]
    }

    var currentEndpoints: [(String, () async -> Void)] {
        switch selectedProvider {
        case 0: return openAIEndpoints
        case 1: return anthropicEndpoints
        case 2: return geminiEndpoints
        case 3: return grokEndpoints
        default: return []
        }
    }

    var safeSelectedEndpoint: Int {
        min(selectedEndpoint, max(0, currentEndpoints.count - 1))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("AISecure SDK Demo")
                .font(.largeTitle)
                .bold()

            Picker("Provider", selection: $selectedProvider) {
                ForEach(0..<providers.count, id: \.self) { index in
                    Text(providers[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedProvider) { _ in
                selectedEndpoint = 0
                output = ""
            }

            Picker("Endpoint", selection: $selectedEndpoint) {
                ForEach(0..<currentEndpoints.count, id: \.self) { index in
                    Text(currentEndpoints[index].0).tag(index)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)

            Button(action: {
                Task {
                    isLoading = true
                    output = "Loading...\n"
                    await currentEndpoints[safeSelectedEndpoint].1()
                    isLoading = false
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    Text("Test \(currentEndpoints[safeSelectedEndpoint].0)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(isLoading || currentEndpoints.isEmpty)

            ScrollView {
                Text(output)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxHeight: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            AISecure.configure(logLevel: .debug, timestamps: true)
        }
    }

    // MARK: - OpenAI Tests

    @MainActor
    func testOpenAIChat() async {
        do {
            let openAI = try AISecure.openAIService(
                serviceURL: "https://xifm3whdw1.execute-api.us-east-2.amazonaws.com/openai-05f0f562c7aa6407",
                backendURL: "https://reproduction-decision-honey-opposition.trycloudflare.com"
            )
            let chatResponse = try await openAI.chat(
                messages: [
                    .init(role: "user", content: "Say hello in one sentence in spanish")
                ],
                model: "gpt-4o-mini-2024-07-18"
            )
            let result = """
            \(timestamp()) ✅ Chat Completion Success

            Content: \(chatResponse.choices.first?.message.content ?? "")
            Model: \(chatResponse.model)
            Tokens: \(chatResponse.usage?.totalTokens ?? 0)
            """
            output = result
            print(result)
        } catch {
            let error = "\(timestamp()) Error: \(error)"
            output = error
            print(error)
        }
    }

    @MainActor
    func testOpenAIImage() async {
        do {
            let openAI = try AISecure.openAIService(
                serviceURL: "https://xifm3whdw1.execute-api.us-east-2.amazonaws.com/openai-05f0f562c7aa6407",
                backendURL: "https://reproduction-decision-honey-opposition.trycloudflare.com"
            )
            let imageResponse = try await openAI.generateImage(
                prompt: "A futuristic cityscape at sunset",
                model: "dall-e-3",
                size: "1024x1024",
                quality: "standard"
            )
            let result = """
            \(timestamp()) ✅ Image Generation Success

            URL: \(imageResponse.data.first?.url ?? "No URL")
            Revised Prompt: \(imageResponse.data.first?.revisedPrompt ?? "N/A")
            Created: \(imageResponse.created)
            """
            output = result
            print(result)
        } catch {
            let error = "\(timestamp()) Error: \(error)"
            output = error
            print(error)
        }
    }

    @MainActor
    func testOpenAIEmbeddings() async {
        do {
            let openAI = try AISecure.openAIService(
                serviceURL: "https://xifm3whdw1.execute-api.us-east-2.amazonaws.com/openai-05f0f562c7aa6407",
                backendURL: "https://reproduction-decision-honey-opposition.trycloudflare.com"
            )
            let embeddingResponse = try await openAI.embeddings(
                input: ["Hello, how are you?", "I'm doing great!"],
                model: "text-embedding-ada-002"
            )
            let result = """
            \(timestamp()) ✅ Embeddings Success

            Model: \(embeddingResponse.model)
            Embeddings Count: \(embeddingResponse.data.count)
            First Embedding Dimensions: \(embeddingResponse.data.first?.embedding.count ?? 0)
            Tokens: \(embeddingResponse.usage.totalTokens)
            """
            output = result
            print(result)
        } catch {
            let error = "\(timestamp()) Error: \(error)"
            output = error
            print(error)
        }
    }

    @MainActor
    func testOpenAITTS() async {
        do {
            let openAI = try AISecure.openAIService(
                serviceURL: "https://xifm3whdw1.execute-api.us-east-2.amazonaws.com/openai-05f0f562c7aa6407",
                backendURL: "https://reproduction-decision-honey-opposition.trycloudflare.com"
            )
            let audioData = try await openAI.textToSpeech(
                input: "Hello, this is a test of text to speech.",
                model: "tts-1",
                voice: "alloy"
            )
            self.audioPlayer = try AVAudioPlayer(data: audioData)
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.play()
            let result = """
            \(timestamp()) ✅ Text-to-Speech Success

            Audio Data Size: \(audioData.count) bytes
            Model: tts-1
            Voice: alloy
            """
            output = result
            print(result)
        } catch {
            let error = "\(timestamp()) Error: \(error)"
            output = error
            print(error)
        }
    }

    @MainActor
    func testOpenAIModeration() async {
        do {
            let openAI = try AISecure.openAIService(
                serviceURL: "https://xifm3whdw1.execute-api.us-east-2.amazonaws.com/openai-05f0f562c7aa6407",
                backendURL: "https://reproduction-decision-honey-opposition.trycloudflare.com"
            )
            let modResponse = try await openAI.moderateContent(
                input: "This is a perfectly safe and friendly message.",
                model: "omni-moderation-latest"
            )
            let result = modResponse.results.first
            let resultText = """
            \(timestamp()) ✅ Content Moderation Success

            Flagged: \(result?.flagged ?? false)
            Model: \(modResponse.model)
            Categories:
              - Hate: \(result?.categories.hate ?? false)
              - Violence: \(result?.categories.violence ?? false)
              - Sexual: \(result?.categories.sexual ?? false)
              - Harassment: \(result?.categories.harassment ?? false)
            """
            output = resultText
            print(resultText)
        } catch {
            let error = "\(timestamp()) Error: \(error)"
            output = error
            print(error)
        }
    }

    // MARK: - Anthropic Tests

    @MainActor
    func testAnthropicMessage() async {
        do {
            let anthropic = try AISecure.anthropicService(
                serviceURL: "https://xifm3whdw1.execute-api.us-east-2.amazonaws.com/anthropic-fe5dc64d1542d764",
                backendURL: "https://reproduction-decision-honey-opposition.trycloudflare.com"
            )
            let response = try await anthropic.createMessage(
                messages: [.init(role: "user", content: "Say a common italian phrase")],
                maxTokens: 100
            )
            let result = """
            \(timestamp()) ✅ Anthropic Message Success

            Content: \(response.content.first?.text ?? "")
            Model: \(response.model)
            Input Tokens: \(response.usage.inputTokens)
            Output Tokens: \(response.usage.outputTokens)
            """
            output = result
            print(result)
        } catch {
            let error = "\(timestamp()) Error: \(error)"
            output = error
            print(error)
        }
    }

    // MARK: - Gemini Tests

    @MainActor
    func testGeminiContent() async {
        do {
            let gemini = try AISecure.geminiService(
                serviceURL: "https://xifm3whdw1.execute-api.us-east-2.amazonaws.com/google-38f9f89279f2f837",
                backendURL: "https://reproduction-decision-honey-opposition.trycloudflare.com"
            )
            let response = try await gemini.generateContent(
                prompt: "Write a haiku about programming",
                model: "gemini-2.0-flash-exp"
            )
            let text = response.candidates?.first?.content?.parts.first?.text
            let result = """
            \(timestamp()) ✅ Gemini Content Generation Success

            Content: \(text ?? "No content")
            Finish Reason: \(response.candidates?.first?.finishReason ?? "N/A")
            Model: \(response.modelVersion ?? "N/A")
            Tokens: \(response.usageMetadata?.totalTokenCount ?? 0)
            """
            output = result
            print(result)
        } catch {
            let error = "\(timestamp()) Error: \(error)"
            output = error
            print(error)
        }
    }

    // MARK: - Grok Tests

    @MainActor
    func testGrokChat() async {
        do {
            let grok = try AISecure.grokService(
                serviceURL: "https://xifm3whdw1.execute-api.us-east-2.amazonaws.com/grok-b25c8f8b098314a7",
                backendURL: "https://reproduction-decision-honey-opposition.trycloudflare.com"
            )
            let chatResponse = try await grok.chat(
                messages: [
                    .init(role: "user", content: "Tell me a fun fact about space in one sentence")
                ],
                model: "grok-4",
                temperature: 0.7
            )
            let result = """
            \(timestamp()) ✅ Grok Chat Completion Success

            Content: \(chatResponse.choices.first?.message.content ?? "")
            Model: \(chatResponse.model)
            Tokens: \(chatResponse.usage?.totalTokens ?? 0)
            """
            output = result
            print(result)
        } catch {
            let error = "\(timestamp()) Error: \(error)"
            output = error
            print(error)
        }
    }

    @MainActor
    func testGrokVision() async {
        do {
            let grok = try AISecure.grokService(
                serviceURL: "https://xifm3whdw1.execute-api.us-east-2.amazonaws.com/grok-b25c8f8b098314a7",
                backendURL: "https://reproduction-decision-honey-opposition.trycloudflare.com"
            )
            let chatResponse = try await grok.chatWithVision(
                messages: [
                    .init(role: "user", content: "Describe what makes a good software architecture")
                ],
                model: "grok-4-1-fast-reasoning",
                temperature: 0.7
            )
            let result = """
            \(timestamp()) ✅ Grok Vision Chat Success

            Content: \(chatResponse.choices.first?.message.content ?? "")
            Model: \(chatResponse.model)
            Tokens: \(chatResponse.usage?.totalTokens ?? 0)
            """
            output = result
            print(result)
        } catch {
            let error = "\(timestamp()) Error: \(error)"
            output = error
            print(error)
        }
    }
}

#Preview {
    ContentView()
}
