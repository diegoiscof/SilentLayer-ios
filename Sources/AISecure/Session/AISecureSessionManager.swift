//
//  AISecureSessionManager.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

@AISecureActor final class AISecureSessionManager: Sendable {
    private let configuration: AISecureConfiguration
    private let storage: AISecureStorage
    private let urlSession: URLSession

    nonisolated(unsafe) private var _currentSession: AISecureSession?
    private var currentSession: AISecureSession? {
        get {
            ProtectedPropertyQueue.session.sync { self._currentSession }
        }
        set {
            ProtectedPropertyQueue.session.async(flags: .barrier) { self._currentSession = newValue }
        }
    }

    private var refreshTask: Task<AISecureSession, Error>?

    nonisolated init(configuration: AISecureConfiguration, storage: AISecureStorage, urlSession: URLSession) {
        self.configuration = configuration
        self.storage = storage
        self.urlSession = urlSession
    }

    func getValidSession() async throws -> AISecureSession {
        let nowMillis = Date().timeIntervalSince1970 * 1000

        if let session = currentSession, isSessionValid(session, at: nowMillis) {
            return session
        }

        if let cached = storage.getSession(for: configuration.projectId),
           isSessionValid(cached, at: nowMillis) {
            currentSession = cached
            return cached
        }

        if let task = refreshTask {
            return try await task.value
        }

        let task = Task {
            let session = try await refreshSession()
            currentSession = session
            storage.saveSession(session, for: configuration.projectId)
            refreshTask = nil
            return session
        }

        refreshTask = task
        return try await task.value
    }

    func invalidateSession() {
        currentSession = nil
        storage.deleteSession(for: configuration.projectId)
    }

    private func isSessionValid(_ session: AISecureSession, at nowMillis: TimeInterval) -> Bool {
        return session.expiresAt > nowMillis
    }

    private func refreshSession() async throws -> AISecureSession {
        logIf(.debug)?.debug("🔑 Refreshing session at: \(self.configuration.backendURL)")

        var request = URLRequest(url: configuration.backendURL.appendingPathComponent("/api/sessions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "projectId": configuration.projectId,
            "deviceFingerprint": configuration.deviceFingerprint
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])

        let (data, response) = try await urlSession.data(for: request)
        try validate(response: response, data: data)

        return try JSONDecoder().decode(AISecureSession.self, from: data)
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
