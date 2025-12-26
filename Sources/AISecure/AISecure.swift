// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public enum AISecure {

    /// The current SDK version
    nonisolated public static let sdkVersion = "2.0.0"

    /// Configures the AISecure SDK logging level
    ///
    /// - Parameter logLevel: The minimum log level to display
    nonisolated public static func configure(logLevel: AISecureLogLevel, timestamps: Bool) {
        AISecureLogLevel.callerDesiredLogLevel = logLevel
        AISecureLogLevel.showTimestamps = timestamps
    }

    // MARK: - Service Initialization

    /// Creates an OpenAI service instance
    ///
    /// 🔒 SECURITY: Credentials are fetched dynamically from backend (no hardcoded keys)
    ///
    /// Features:
    /// - Full OpenAI API support (chat, embeddings, audio, vision, etc.)
    /// - Model can be specified from SDK or configured in dashboard
    /// - Raw OpenAI response format
    /// - Dynamic credential issuance via JWT
    ///
    /// - Parameters:
    ///   - serviceURL: The service gateway URL (format: https://api.gateway.com/openai-{serviceId})
    ///   - backendURL: The AISecure backend URL
    ///
    /// - Returns: An instance of OpenAIService configured and ready to make requests
    ///
    /// - Throws: AISecureError if the configuration is invalid
    @MainActor
    public static func openAIService(
        serviceURL: String,
        backendURL: String
    ) throws -> OpenAIService {
        let (configuration, sessionManager, requestBuilder, urlSession, deviceAuth) = try createServiceDependenciesWithJWT(
            provider: "openai",
            serviceURL: serviceURL,
            backendURL: backendURL
        )

        return OpenAIService(
            configuration: configuration,
            sessionManager: sessionManager,
            requestBuilder: requestBuilder,
            urlSession: urlSession,
            deviceAuthenticator: deviceAuth
        )
    }

    /// Creates an Anthropic service instance
    ///
    /// 🔒 SECURITY: Credentials are fetched dynamically from backend (no hardcoded keys)
    ///
    /// Features:
    /// - Full Anthropic API support (messages, function calling, vision, etc.)
    /// - Model can be specified from SDK or configured in dashboard
    /// - Raw Anthropic response format
    /// - Dynamic credential issuance via JWT
    ///
    /// - Parameters:
    ///   - serviceURL: The service gateway URL (format: https://api.gateway.com/anthropic-{serviceId})
    ///   - backendURL: The AISecure backend URL
    ///
    /// - Returns: An instance of AnthropicService configured and ready to make requests
    ///
    /// - Throws: AISecureError if the configuration is invalid
    @MainActor
    public static func anthropicService(
        serviceURL: String,
        backendURL: String
    ) throws -> AnthropicService {
        let (configuration, sessionManager, requestBuilder, urlSession, deviceAuth) = try createServiceDependenciesWithJWT(
            provider: "anthropic",
            serviceURL: serviceURL,
            backendURL: backendURL
        )

        return AnthropicService(
            configuration: configuration,
            sessionManager: sessionManager,
            requestBuilder: requestBuilder,
            urlSession: urlSession,
            deviceAuthenticator: deviceAuth
        )
    }

    /// Creates a Gemini service instance
    ///
    /// 🔒 SECURITY: Credentials are fetched dynamically from backend (no hardcoded keys)
    ///
    /// Features:
    /// - Full Gemini API support (content generation, vision, multi-modal)
    /// - Model can be specified from SDK or configured in dashboard
    /// - Raw Gemini response format
    /// - Dynamic credential issuance via JWT
    ///
    /// - Parameters:
    ///   - serviceURL: The service gateway URL (format: https://api.gateway.com/gemini-{serviceId})
    ///   - backendURL: The AISecure backend URL
    ///
    /// - Returns: An instance of GeminiService configured and ready to make requests
    ///
    /// - Throws: AISecureError if the configuration is invalid
    @MainActor
    public static func geminiService(
        serviceURL: String,
        backendURL: String
    ) throws -> GeminiService {
        let (configuration, sessionManager, requestBuilder, urlSession, deviceAuth) = try createServiceDependenciesWithJWT(
            provider: "gemini",
            serviceURL: serviceURL,
            backendURL: backendURL
        )

        return GeminiService(
            configuration: configuration,
            sessionManager: sessionManager,
            requestBuilder: requestBuilder,
            urlSession: urlSession,
            deviceAuthenticator: deviceAuth
        )
    }

    /// Creates a Grok service instance
    ///
    /// 🔒 SECURITY: Credentials are fetched dynamically from backend (no hardcoded keys)
    ///
    /// Features:
    /// - OpenAI-compatible API (chat completions)
    /// - Vision capabilities (grok-vision-beta)
    /// - Model can be specified from SDK or configured in dashboard
    /// - Raw OpenAI-compatible response format
    /// - Dynamic credential issuance via JWT
    ///
    /// - Parameters:
    ///   - serviceURL: The service gateway URL (format: https://api.gateway.com/grok-{serviceId})
    ///   - backendURL: The AISecure backend URL
    ///
    /// - Returns: An instance of GrokService configured and ready to make requests
    ///
    /// - Throws: AISecureError if the configuration is invalid
    @MainActor
    public static func grokService(
        serviceURL: String,
        backendURL: String
    ) throws -> GrokService {
        let (configuration, sessionManager, requestBuilder, urlSession, deviceAuth) = try createServiceDependenciesWithJWT(
            provider: "grok",
            serviceURL: serviceURL,
            backendURL: backendURL
        )

        return GrokService(
            configuration: configuration,
            sessionManager: sessionManager,
            requestBuilder: requestBuilder,
            urlSession: urlSession,
            deviceAuthenticator: deviceAuth
        )
    }

    // MARK: - Private Helpers

    /// Creates service dependencies with JWT-based authentication
    /// 🔒 SECURITY: Credentials fetched dynamically from backend, no hardcoded keys
    @MainActor
    private static func createServiceDependenciesWithJWT(
        provider: String,
        serviceURL: String,
        backendURL: String
    ) throws -> (AISecureConfiguration, AISecureSessionManager, AISecureRequestBuilder, URLSession, AISecureDeviceAuthenticator) {
        guard let url = URL(string: backendURL) else {
            throw AISecureError.invalidConfiguration("Invalid backend URL: \(backendURL)")
        }

        let deviceFingerprint = DeviceIdentifier.get()
        let urlSession = createURLSession()
        let storage = AISecureStorage()

        // Create device authenticator (gets JWT with dynamic credentials)
        let deviceAuth = AISecureDeviceAuthenticator(
            backendURL: url,
            serviceURL: serviceURL,
            deviceFingerprint: deviceFingerprint,
            urlSession: urlSession,
            storage: storage
        )

        // Temporary service config (will be replaced with JWT credentials)
        let temporaryService = try AISecureServiceConfig(
            provider: provider,
            serviceURL: serviceURL,
            partialKey: "temporary" // Will be replaced by JWT payload
        )

        let configuration = AISecureConfiguration(
            backendURL: url,
            deviceFingerprint: deviceFingerprint,
            service: temporaryService
        )

        let sessionManager = AISecureSessionManager(
            configuration: configuration,
            storage: storage,
            urlSession: urlSession
        )
        let requestBuilder = AISecureDefaultRequestBuilder(configuration: configuration)

        return (configuration, sessionManager, requestBuilder, urlSession, deviceAuth)
    }

    @MainActor
    private static func createServiceDependencies(
        service: AISecureServiceConfig,
        backendURL: String
    ) throws -> (AISecureConfiguration, AISecureSessionManager, AISecureRequestBuilder, URLSession) {
        guard let url = URL(string: backendURL) else {
            throw AISecureError.invalidConfiguration("Invalid backend URL: \(backendURL)")
        }

        let deviceFingerprint = DeviceIdentifier.get()

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
