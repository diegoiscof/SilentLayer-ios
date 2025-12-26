//
//  OpenAIService.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

@AISecureActor public class OpenAIService: Sendable {
    private var configuration: AISecureConfiguration
    private let sessionManager: AISecureSessionManager
    private let requestBuilder: AISecureRequestBuilder
    private let urlSession: URLSession
    private let deviceAuthenticator: AISecureDeviceAuthenticator?

    nonisolated init(
        configuration: AISecureConfiguration,
        sessionManager: AISecureSessionManager,
        requestBuilder: AISecureRequestBuilder,
        urlSession: URLSession,
        deviceAuthenticator: AISecureDeviceAuthenticator? = nil
    ) {
        self.configuration = configuration
        self.sessionManager = sessionManager
        self.requestBuilder = requestBuilder
        self.urlSession = urlSession
        self.deviceAuthenticator = deviceAuthenticator
    }


    /// Creates a chat completion request
    ///
    /// - Parameters:
    ///   - messages: Array of chat messages
    ///   - model: The model to use (default: "gpt-4")
    ///   - temperature: Sampling temperature between 0 and 2 (default: 0.7)
    /// - Returns: The chat completion response
    public func chat(
        messages: [ChatMessage],
        model: String = "",
        temperature: Double = 1
    ) async throws -> OpenAIChatResponse {
        guard !messages.isEmpty else {
            throw AISecureError.invalidConfiguration("Messages cannot be empty")
        }
        guard (0...2).contains(temperature) else {
            throw AISecureError.invalidConfiguration("Temperature must be between 0 and 2")
        }

        let body: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": temperature
        ]

        return try await jsonRequest(
            endpoint: "/v1/chat/completions",
            body: body,
            response: OpenAIChatResponse.self
        )
    }

    /// Creates embeddings for the input text
    ///
    /// - Parameters:
    ///   - input: Array of strings to create embeddings for
    ///   - model: The model to use (default: "text-embedding-ada-002")
    /// - Returns: The embeddings response
    public func embeddings(
        input: [String],
        model: String = "text-embedding-ada-002"
    ) async throws -> OpenAIEmbeddingsResponse {
        guard !input.isEmpty else {
            throw AISecureError.invalidConfiguration("Input cannot be empty")
        }

        let body: [String: Any] = [
            "model": model,
            "input": input
        ]

        return try await jsonRequest(
            endpoint: "/v1/embeddings",
            body: body,
            response: OpenAIEmbeddingsResponse.self
        )
    }

    /// Converts text to speech
    ///
    /// - Parameters:
    ///   - input: The text to convert to speech
    ///   - model: The model to use (default: "tts-1")
    ///   - voice: The voice to use (default: "alloy")
    /// - Returns: Audio data
    public func textToSpeech(
        input: String,
        model: String = "tts-1",
        voice: String = "alloy"
    ) async throws -> Data {
        guard !input.isEmpty else {
            throw AISecureError.invalidConfiguration("Input cannot be empty")
        }

        let body: [String: Any] = [
            "model": model,
            "input": input,
            "voice": voice
        ]

        return try await binaryRequest(
            endpoint: "/v1/audio/speech",
            body: body
        )
    }

    /// Generates images using DALL-E
    ///
    /// - Parameters:
    ///   - prompt: A text description of the desired image(s)
    ///   - model: The model to use (default: "dall-e-3")
    ///   - n: Number of images to generate (1-10, default: 1)
    ///   - size: Size of generated images (default: "1024x1024")
    ///   - quality: Quality of image (default: "standard")
    ///   - responseFormat: Format of response - "url" or "b64_json" (default: "url")
    /// - Returns: Image generation response
    public func generateImage(
        prompt: String,
        model: String = "dall-e-3",
        n: Int = 1,
        size: String = "1024x1024",
        quality: String = "standard",
        responseFormat: String = "url"
    ) async throws -> OpenAIImageGenerationResponse {
        guard !prompt.isEmpty else {
            throw AISecureError.invalidConfiguration("Prompt cannot be empty")
        }
        guard (1...10).contains(n) else {
            throw AISecureError.invalidConfiguration("Number of images must be between 1 and 10")
        }

        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "n": n,
            "size": size,
            "quality": quality,
            "response_format": responseFormat
        ]

        return try await jsonRequest(
            endpoint: "/v1/images/generations",
            body: body,
            response: OpenAIImageGenerationResponse.self
        )
    }

    /// Moderates text content for harmful content
    ///
    /// - Parameters:
    ///   - input: The text to moderate
    ///   - model: The model to use (default: "omni-moderation-latest")
    /// - Returns: Moderation response with flagged categories
    public func moderateContent(
        input: String,
        model: String = "omni-moderation-latest"
    ) async throws -> OpenAIModerationResponse {
        guard !input.isEmpty else {
            throw AISecureError.invalidConfiguration("Input cannot be empty")
        }

        let body: [String: Any] = [
            "model": model,
            "input": input
        ]

        return try await jsonRequest(
            endpoint: "/v1/moderations",
            body: body,
            response: OpenAIModerationResponse.self
        )
    }

    // MARK: - Private Methods

    private func jsonRequest<T: Decodable>(
        endpoint: String,
        body: [String: Any],
        response: T.Type
    ) async throws -> T {
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        let (data, urlResponse) = try await AISecureServiceHelpers.executeWithRetry(
            deviceAuthenticator: deviceAuthenticator,
            sessionManager: sessionManager,
            configuration: configuration
        ) { service, session in
            let request = self.requestBuilder.buildRequest(
                endpoint: endpoint,
                body: bodyData,
                session: session,
                service: service
            )
            return try await self.urlSession.data(for: request)
        }

        try AISecureServiceHelpers.validateResponse(urlResponse, data: data)

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AISecureError.decodingError(error)
        }
    }

    private func binaryRequest(
        endpoint: String,
        body: [String: Any]
    ) async throws -> Data {
        let bodyData = try JSONSerialization.data(
            withJSONObject: body,
            options: [.sortedKeys]
        )

        let (data, urlResponse) = try await AISecureServiceHelpers.executeWithRetry(
            deviceAuthenticator: deviceAuthenticator,
            sessionManager: sessionManager,
            configuration: configuration
        ) { service, session in
            let request = self.requestBuilder.buildRequest(
                endpoint: endpoint,
                body: bodyData,
                session: session,
                service: service
            )
            return try await self.urlSession.data(for: request)
        }

        try AISecureServiceHelpers.validateResponse(urlResponse, data: data)
        return data
    }
}
