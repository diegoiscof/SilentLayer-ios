//
// ContentView.swift
// SilentLayerDemo
//
// Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import SwiftUI
import SilentLayer
import AVFoundation

func timestamp() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    let now = Date()
    let timeString = formatter.string(from: now)
    let milliseconds = Int(now.timeIntervalSince1970 * 1000) % 1000
    return "[\(timeString).\(String(format: "%03d", milliseconds))]"
}

enum Provider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case gemini = "Gemini"
    case grok = "Grok"
    
    var id: Self { self }
}

struct Endpoint {
    let name: String
    let test: () async -> Void
}

struct ContentView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var selectedProvider: Provider = .openAI
    @State private var selectedEndpoint = 0
    @State private var output = ""
    @State private var isLoading = false
    
    private let openAIServiceURL = ""
    private let anthropicServiceURL = ""
    private let geminiServiceURL = ""
    private let grokServiceURL = ""
    
    private var currentEndpoints: [Endpoint] {
        switch selectedProvider {
        case .openAI:
            return [
                .init(name: "Chat Completion", test: testOpenAIChat),
                .init(name: "Chat Completion (Streaming)", test: testOpenAIChatStream),
                .init(name: "Chat with Structured Output", test: testOpenAIStructuredOutput),
                .init(name: "Chat with Reasoning (o1/o3)", test: testOpenAIReasoning),
                .init(name: "Responses API", test: testOpenAIResponse),
                .init(name: "Responses API (Streaming)", test: testOpenAIResponseStream),
                .init(name: "Image Generation (DALL-E)", test: testOpenAIImage),
                .init(name: "Embeddings", test: testOpenAIEmbeddings),
                .init(name: "Text-to-Speech", test: testOpenAITTS),
                .init(name: "Content Moderation", test: testOpenAIModeration)
            ]
        case .anthropic:
            return [
                .init(name: "Create Message", test: testAnthropicMessage),
                .init(name: "Create Message (Streaming)", test: testAnthropicMessageStream)
            ]
        case .gemini:
            return [
                .init(name: "Generate Content", test: testGeminiContent)
            ]
        case .grok:
            return [
                .init(name: "Chat Completion", test: testGrokChat),
                .init(name: "Chat Completion (Streaming)", test: testGrokChatStream),
                .init(name: "Chat with Vision", test: testGrokVision)
            ]
        }
    }
    
    private var safeSelectedEndpoint: Int {
        max(0, min(selectedEndpoint, currentEndpoints.count - 1))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("SilentLayer SDK Demo")
                .font(.largeTitle)
                .bold()
            
            Picker("Provider", selection: $selectedProvider) {
                ForEach(Provider.allCases) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedProvider) {
                selectedEndpoint = 0
                output = ""
            }
            
            Picker("Endpoint", selection: $selectedEndpoint) {
                ForEach(currentEndpoints.indices, id: \.self) { index in
                    Text(currentEndpoints[index].name).tag(index)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            
            Button {
                Task {
                    isLoading = true
                    output = "Loading...\n"
                    await currentEndpoints[safeSelectedEndpoint].test()
                    isLoading = false
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Text("Test \(currentEndpoints[safeSelectedEndpoint].name)")
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
            SilentLayer.configure(logLevel: .debug, timestamps: false)
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleError(_ error: Error) {
        let errorMessage = "\(timestamp()) Error: \(error.localizedDescription)"
        output = errorMessage
        print(errorMessage)
    }
    
    private func formatRateLimitMessage(_ info: SilentLayerRateLimitInfo) -> String {
        var message = "Rate limit reached."
        if let used = info.used, let limit = info.limit {
            message += " (\(used)/\(limit)"
            if let period = info.period {
                message += " \(period)"
            }
            message += ")"
        }
        message += " Try again in \(formatDuration(info.retryAfter))."
        return message
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            return "\(seconds / 60)m \(seconds % 60)s"
        } else {
            return "\(seconds / 3600)h \(seconds % 3600 / 60)m"
        }
    }
}

// MARK: - OpenAI Tests

extension ContentView {
    @MainActor
    func testOpenAIChat() async {
        do {
            let openAI = try SilentLayer.openAIService(serviceURL: openAIServiceURL)
            let chatResponse = try await openAI.chat(
                messages: [.init(role: "user", content: "Say hello in one sentence in spanish")],
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
        } catch let error as SilentLayerError {
            switch error {
            case .userRateLimited(let info):
                output = "⏳ \(formatRateLimitMessage(info))"
            case .planQuotaExceeded(let info):
                output = "📊 Service quota reached. Resets in \(formatDuration(info.retryAfter))."
            default:
                handleError(error)
            }
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    func testOpenAIChatStream() async {
        do {
            let openAI = try SilentLayer.openAIService(serviceURL: openAIServiceURL)
            output = "\(timestamp()) ⚡ Starting OpenAI Streaming Chat...\n\n"
            var fullResponse = ""
            try await openAI.chatStream(
                messages: [.init(role: "user", content: "Count from 1 to 10, one number per line")],
                model: "gpt-4o-mini-2024-07-18"
            ) { delta in
                Task { @MainActor in
                    if let content = delta.choices.first?.delta.content {
                        fullResponse += content
                        output = """
                        \(timestamp()) ⚡ Streaming...
                        \(fullResponse)
                        """
                    }
                    if let finishReason = delta.choices.first?.finishReason, finishReason == "stop" {
                        output += "\n\n\(timestamp()) ✅ Stream Complete!"
                    }
                }
            }
            let finalOutput = """
            \(timestamp()) ✅ OpenAI Chat Stream Success
            Full Response:
            \(fullResponse)
            Model: gpt-4o-mini-2024-07-18
            """
            output = finalOutput
            print(finalOutput)
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    func testOpenAIStructuredOutput() async {
        do {
            let openAI = try SilentLayer.openAIService(serviceURL: openAIServiceURL)
            let schema: [String: Any] = [
                "type": "object",
                "properties": [
                    "name": ["type": "string"],
                    "age": ["type": "number"],
                    "occupation": ["type": "string"],
                    "skills": [
                        "type": "array",
                        "items": ["type": "string"]
                    ]
                ],
                "required": ["name", "age", "occupation", "skills"],
                "additionalProperties": false
            ]
            let chatResponse = try await openAI.chat(
                messages: [.init(role: "user", content: "Create a fictional software engineer profile")],
                model: "gpt-4o-mini-2024-07-18",
                responseFormat: .jsonSchema(name: "engineer_profile", schema: schema, strict: true)
            )
            let result = """
            \(timestamp()) ✅ Structured Output Success
            JSON Response:
            \(chatResponse.choices.first?.message.content ?? "")
            Model: \(chatResponse.model)
            Tokens: \(chatResponse.usage?.totalTokens ?? 0)
            Response Format: JSON Schema (strict)
            """
            output = result
            print(result)
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    func testOpenAIReasoning() async {
        do {
            let openAI = try SilentLayer.openAIService(serviceURL: openAIServiceURL)
            let chatResponse = try await openAI.chat(
                messages: [.init(role: "user", content: "Solve: If a train travels 120 miles in 2 hours, how long will it take to travel 300 miles at the same speed?")],
                model: "o1-2024-12-17",
                reasoningEffort: .high
            )
            let result = """
            \(timestamp()) ✅ Chat Success (Reasoning Problem)
            Response:
            \(chatResponse.choices.first?.message.content ?? "")
            Model: \(chatResponse.model)
            Tokens: \(chatResponse.usage?.totalTokens ?? 0)
            Note: To use reasoning_effort parameter, use o1 or o3 models.
            """
            output = result
            print(result)
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    func testOpenAIResponse() async {
        do {
            let openAI = try SilentLayer.openAIService(serviceURL: openAIServiceURL)
            let response = try await openAI.createResponse(
                input: "Explain what makes Swift a great programming language in 2 sentences",
                model: "gpt-4o-mini-2024-07-18"
            )
            var outputText = ""
            if let outputItems = response.output {
                for item in outputItems {
                    if case .message(let msg) = item {
                        for content in msg.content {
                            if case .outputText(let text) = content {
                                outputText += text
                            }
                        }
                    }
                }
            }
            let result = """
            \(timestamp()) ✅ Responses API Success
            Response:
            \(outputText)
            Model: \(response.model ?? "N/A")
            Status: \(response.status?.rawValue ?? "N/A")
            Input Tokens: \(response.usage?.inputTokens ?? 0)
            Output Tokens: \(response.usage?.outputTokens ?? 0)
            Total Tokens: \(response.usage?.totalTokens ?? 0)
            Note: To use reasoning_effort, use o1 or o3 models.
            """
            output = result
            print(result)
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    func testOpenAIResponseStream() async {
        do {
            let openAI = try SilentLayer.openAIService(serviceURL: openAIServiceURL)
            output = "\(timestamp()) ⚡ Starting Responses API Streaming...\n\n"
            var fullResponse = ""
            try await openAI.createResponseStream(
                input: "List 5 benefits of using AI in software development",
                model: "gpt-4o-mini-2024-07-18"
            ) { event in
                Task { @MainActor in
                    switch event.type {
                    case "response.output_text.delta":
                        if let delta = event.delta {
                            fullResponse += delta
                            self.output = """
                            \(timestamp()) ⚡ Streaming...
                            \(fullResponse)
                            """
                        }
                    case "response.completed":
                        self.output += "\n\n\(timestamp()) ✅ Stream Complete!"
                    default:
                        break
                    }
                }
            }
            let finalOutput = """
            \(timestamp()) ✅ Responses API Stream Success
            Full Response:
            \(fullResponse)
            Model: gpt-4o-mini-2024-07-18
            Note: To use reasoning_effort, use o1 or o3 models.
            """
            output = finalOutput
            print(finalOutput)
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    func testOpenAIImage() async {
        do {
            let openAI = try SilentLayer.openAIService(serviceURL: openAIServiceURL)
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
            handleError(error)
        }
    }
    
    @MainActor
    func testOpenAIEmbeddings() async {
        do {
            let openAI = try SilentLayer.openAIService(serviceURL: openAIServiceURL)
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
            handleError(error)
        }
    }
    
    @MainActor
    func testOpenAITTS() async {
        do {
            let openAI = try SilentLayer.openAIService(serviceURL: openAIServiceURL)
            let audioData = try await openAI.textToSpeech(
                input: "Hello, this is a test of text to speech.",
                model: "tts-1",
                voice: "alloy"
            )
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            let result = """
            \(timestamp()) ✅ Text-to-Speech Success
            Audio Data Size: \(audioData.count) bytes
            Model: tts-1
            Voice: alloy
            """
            output = result
            print(result)
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    func testOpenAIModeration() async {
        do {
            let openAI = try SilentLayer.openAIService(serviceURL: openAIServiceURL)
            let modResponse = try await openAI.moderateContent(
                input: "This is a perfectly safe and friendly message.",
                model: "omni-moderation-latest"
            )
            let resultItem = modResponse.results.first
            let resultText = """
            \(timestamp()) ✅ Content Moderation Success
            Flagged: \(resultItem?.flagged ?? false)
            Model: \(modResponse.model)
            Categories:
              - Hate: \(resultItem?.categories.hate ?? false)
              - Violence: \(resultItem?.categories.violence ?? false)
              - Sexual: \(resultItem?.categories.sexual ?? false)
              - Harassment: \(resultItem?.categories.harassment ?? false)
            """
            output = resultText
            print(resultText)
        } catch {
            handleError(error)
        }
    }
}

// MARK: - Anthropic Tests

extension ContentView {
    @MainActor
    func testAnthropicMessage() async {
        do {
            let anthropic = try SilentLayer.anthropicService(serviceURL: anthropicServiceURL)
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
            handleError(error)
        }
    }
    
    @MainActor
    func testAnthropicMessageStream() async {
        do {
            let anthropic = try SilentLayer.anthropicService(serviceURL: anthropicServiceURL)
            output = "\(timestamp()) ⚡ Starting Anthropic Streaming Message...\n\n"
            var fullResponse = ""
            try await anthropic.createMessageStream(
                messages: [.init(role: "user", content: "Write a short haiku about coding")],
                maxTokens: 200
            ) { delta in
                Task { @MainActor in
                    if let text = delta.delta?.text {
                        fullResponse += text
                        output = """
                        \(timestamp()) ⚡ Streaming...
                        \(fullResponse)
                        """
                    } else if delta.delta?.thinking != nil {
                        print("🧠 Claude is thinking...")
                    }
                    if delta.type == "message_stop" {
                        output += "\n\n\(timestamp()) ✅ Stream Complete!"
                    }
                }
            }
            let finalOutput = """
            \(timestamp()) ✅ Anthropic Message Stream Success
            Full Response:
            \(fullResponse)
            Model: claude-sonnet-4-5-20250929
            """
            output = finalOutput
            print(finalOutput)
        } catch {
            handleError(error)
        }
    }
}

// MARK: - Gemini Tests

extension ContentView {
    @MainActor
    func testGeminiContent() async {
        do {
            let gemini = try SilentLayer.geminiService(serviceURL: geminiServiceURL)
            let response = try await gemini.generateContent(
                prompt: "Write a haiku about programming",
                model: "gemini-2.0-flash-exp"
            )
            let text = response.candidates?.first?.content?.parts.first?.text ?? "No content"
            let result = """
            \(timestamp()) ✅ Gemini Content Generation Success
            Content: \(text)
            Finish Reason: \(response.candidates?.first?.finishReason ?? "N/A")
            Model: \(response.modelVersion ?? "N/A")
            Tokens: \(response.usageMetadata?.totalTokenCount ?? 0)
            """
            output = result
            print(result)
        } catch {
            handleError(error)
        }
    }
}

// MARK: - Grok Tests

extension ContentView {
    @MainActor
    func testGrokChat() async {
        do {
            let grok = try SilentLayer.grokService(serviceURL: grokServiceURL)
            let chatResponse = try await grok.chat(
                messages: [.init(role: "user", content: "Tell me a fun fact about space in one sentence")],
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
            handleError(error)
        }
    }
    
    @MainActor
    func testGrokChatStream() async {
        do {
            let grok = try SilentLayer.grokService(serviceURL: grokServiceURL)
            output = "\(timestamp()) ⚡ Starting Grok Streaming Chat...\n\n"
            var fullResponse = ""
            try await grok.chatStream(
                messages: [.init(role: "user", content: "Count from 1 to 5, one number per line")],
                model: "grok-4",
                temperature: 0.7
            ) { delta in
                Task { @MainActor in
                    if let content = delta.choices.first?.delta.content {
                        fullResponse += content
                        output = """
                        \(timestamp()) ⚡ Streaming...
                        \(fullResponse)
                        """
                    }
                    if let finishReason = delta.choices.first?.finishReason, finishReason == "stop" {
                        output += "\n\n\(timestamp()) ✅ Stream Complete!"
                    }
                }
            }
            let finalOutput = """
            \(timestamp()) ✅ Grok Chat Stream Success
            Full Response:
            \(fullResponse)
            Model: grok-4
            """
            output = finalOutput
            print(finalOutput)
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    func testGrokVision() async {
        do {
            let grok = try SilentLayer.grokService(serviceURL: grokServiceURL)
            let chatResponse = try await grok.chatWithVision(
                messages: [.init(role: "user", content: "Describe what makes a good software architecture")],
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
            handleError(error)
        }
    }
}

#Preview {
    ContentView()
}
