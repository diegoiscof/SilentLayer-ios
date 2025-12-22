//
//  OpenAIService.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

@AISecureActor public class OpenAIService: Sendable {
    private let configuration: AISecureConfiguration
    private let sessionManager: AISecureSessionManager
    private let requestBuilder: AISecureRequestBuilder
    private let urlSession: URLSession

    nonisolated init(
        configuration: AISecureConfiguration,
        sessionManager: AISecureSessionManager,
        requestBuilder: AISecureRequestBuilder,
        urlSession: URLSession
    ) {
        self.configuration = configuration
        self.sessionManager = sessionManager
        self.requestBuilder = requestBuilder
        self.urlSession = urlSession
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
        model: String = "gpt-4",
        temperature: Double = 0.7
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
            provider: "openai",
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
            provider: "openai",
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
            provider: "openai",
            endpoint: "/v1/audio/speech",
            body: body
        )
    }

    // MARK: - Private Methods

    private func jsonRequest<T: Decodable>(
        provider: String,
        endpoint: String,
        body: [String: Any],
        response: T.Type
    ) async throws -> T {
        let session = try await sessionManager.getValidSession()

        guard let service = configuration.service(for: provider) else {
            throw AISecureError.providerNotConfigured(provider)
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let request = requestBuilder.buildRequest(
            endpoint: endpoint,
            body: bodyData,
            session: session,
            service: service
        )

        let (data, urlResponse) = try await urlSession.data(for: request)
        try validate(response: urlResponse, data: data)

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AISecureError.decodingError(error)
        }
    }

    private func binaryRequest(
        provider: String,
        endpoint: String,
        body: [String: Any]
    ) async throws -> Data {
        let session = try await sessionManager.getValidSession()

        guard let service = configuration.service(for: provider) else {
            throw AISecureError.providerNotConfigured(provider)
        }

        let bodyData = try JSONSerialization.data(
            withJSONObject: body,
            options: [.sortedKeys]
        )

        let request = requestBuilder.buildRequest(
            endpoint: endpoint,
            body: bodyData,
            session: session,
            service: service
        )

        logIf(.debug)?.debug("➡️ Binary request to \(endpoint)")

        let (data, urlResponse) = try await urlSession.data(for: request)
        try validate(response: urlResponse, data: data)

        return data
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AISecureError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let body: Any
            do {
                body = try JSONSerialization.jsonObject(with: data)
            } catch {
                body = [
                    "error": "Failed to parse error response",
                    "raw": String(data: data, encoding: .utf8) ?? "Unable to decode data"
                ]
            }

            logIf(.error)?.error("HTTP \(http.statusCode) error: \(String(describing: body))")
            throw AISecureError.httpError(status: http.statusCode, body: body)
        }
    }
}
