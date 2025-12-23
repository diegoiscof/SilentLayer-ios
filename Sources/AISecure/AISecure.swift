// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public enum AISecure {

    /// The current SDK version
    nonisolated public static let sdkVersion = "2.0.0"

    /// Configures the AISecure SDK logging level
    ///
    /// - Parameter logLevel: The minimum log level to display
    nonisolated public static func configure(logLevel: AISecureLogLevel) {
        AISecureLogLevel.callerDesiredLogLevel = logLevel
    }

    // MARK: - Service Initialization

    /// Creates an OpenAI service instance
    ///
    /// Features:
    /// - Full OpenAI API support (chat, embeddings, audio, vision, etc.)
    /// - Model can be specified from SDK or configured in dashboard
    /// - Raw OpenAI response format
    ///
    /// - Parameters:
    ///   - serviceURL: The service gateway URL (format: https://api.gateway.com/openai-{serviceId})
    ///   - partialKey: The partial API key
    ///   - backendURL: The AISecure backend URL
    ///
    /// - Returns: An instance of OpenAIService configured and ready to make requests
    ///
    /// - Throws: AISecureError if the configuration is invalid
    @MainActor
    public static func openAIService(
        serviceURL: String,
        partialKey: String,
        backendURL: String
    ) throws -> OpenAIService {
        let service = try AISecureServiceConfig(
            provider: "openai",
            serviceURL: serviceURL,
            partialKey: partialKey
        )

        let (configuration, sessionManager, requestBuilder, urlSession) = try createServiceDependencies(
            service: service,
            backendURL: backendURL
        )

        return OpenAIService(
            configuration: configuration,
            sessionManager: sessionManager,
            requestBuilder: requestBuilder,
            urlSession: urlSession
        )
    }

    /// Creates an Anthropic service instance
    ///
    /// Features:
    /// - Full Anthropic API support (messages, function calling, vision, etc.)
    /// - Model can be specified from SDK or configured in dashboard
    /// - Raw Anthropic response format
    ///
    /// - Parameters:
    ///   - serviceURL: The service gateway URL (format: https://api.gateway.com/anthropic-{serviceId})
    ///   - partialKey: The partial API key
    ///   - backendURL: The AISecure backend URL
    ///
    /// - Returns: An instance of AnthropicService configured and ready to make requests
    ///
    /// - Throws: AISecureError if the configuration is invalid
    @MainActor
    public static func anthropicService(
        serviceURL: String,
        partialKey: String,
        backendURL: String
    ) throws -> AnthropicService {
        let service = try AISecureServiceConfig(
            provider: "anthropic",
            serviceURL: serviceURL,
            partialKey: partialKey
        )

        let (configuration, sessionManager, requestBuilder, urlSession) = try createServiceDependencies(
            service: service,
            backendURL: backendURL
        )

        return AnthropicService(
            configuration: configuration,
            sessionManager: sessionManager,
            requestBuilder: requestBuilder,
            urlSession: urlSession
        )
    }

    // MARK: - Private Helpers

    @MainActor
    private static func createServiceDependencies(
        service: AISecureServiceConfig,
        backendURL: String
    ) throws -> (AISecureConfiguration, AISecureSessionManager, AISecureRequestBuilder, URLSession) {
        guard let url = URL(string: backendURL) else {
            throw AISecureError.invalidConfiguration("Invalid backend URL: \(backendURL)")
        }

        let deviceFingerprint = DeviceFingerprint.generate()

        let configuration = AISecureConfiguration(
            backendURL: url,
            deviceFingerprint: deviceFingerprint,
            service: service
        )

        let urlSession = createURLSession()
        let storage = AISecureStorage()
        let sessionManager = AISecureSessionManager(
            configuration: configuration,
            storage: storage,
            urlSession: urlSession
        )
        let requestBuilder = AISecureDefaultRequestBuilder(configuration: configuration)

        return (configuration, sessionManager, requestBuilder, urlSession)
    }

    /// Creates a URLSession configured for AISecure
    private static func createURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }
}
