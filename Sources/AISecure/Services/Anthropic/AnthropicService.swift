//
//  AnthropicService.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

@AISecureActor public class AnthropicService: Sendable {
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

    /// Creates a message with Claude
    ///
    /// - Parameters:
    ///   - messages: Array of messages
    ///   - model: The model to use (default: "claude-sonnet-4-5-20250929")
    ///   - maxTokens: Maximum tokens to generate
    ///   - temperature: Sampling temperature between 0 and 1 (default: 0.7)
    /// - Returns: The message response
    public func createMessage(
        messages: [AnthropicMessage],
        model: String = "claude-sonnet-4-5-20250929",
        maxTokens: Int = 1024,
        temperature: Double = 0.7
    ) async throws -> AnthropicMessageResponse {
        guard !messages.isEmpty else {
            throw AISecureError.invalidConfiguration("Messages cannot be empty")
        }
        guard (0...1).contains(temperature) else {
            throw AISecureError.invalidConfiguration("Temperature must be between 0 and 1")
        }

        let body: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "max_tokens": maxTokens,
            "temperature": temperature
        ]

        return try await jsonRequest(
            endpoint: "/v1/messages",
            body: body,
            response: AnthropicMessageResponse.self
        )
    }

    // MARK: - Private Methods

    private func jsonRequest<T: Decodable>(
        endpoint: String,
        body: [String: Any],
        response: T.Type
    ) async throws -> T {
        var retriedOnce = false

        while true {
            let session = try await sessionManager.getValidSession(forceRefresh: retriedOnce)
            let service = configuration.service

            let bodyData = try JSONSerialization.data(withJSONObject: body)
            let request = requestBuilder.buildRequest(
                endpoint: endpoint,
                body: bodyData,
                session: session,
                service: service
            )

            logIf(.debug)?.debug("➡️ Request to \(endpoint)")

            let (data, urlResponse) = try await urlSession.data(for: request)

            // Check for 401 error - session expired
            if let http = urlResponse as? HTTPURLResponse, http.statusCode == 401, !retriedOnce {
                logIf(.info)?.info("⚠️ Session expired, refreshing and retrying...")
                sessionManager.invalidateSession()
                retriedOnce = true
                continue
            }

            try validate(response: urlResponse, data: data)

            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw AISecureError.decodingError(error)
            }
        }
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
