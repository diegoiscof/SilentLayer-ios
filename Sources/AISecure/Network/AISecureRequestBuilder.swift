//
//  AISecureRequestBuilder.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation
import CryptoKit

@AISecureActor protocol AISecureRequestBuilder: Sendable {
    func buildRequest(
        endpoint: String,
        body: Data,
        session: AISecureSession,
        service: AISecureServiceConfig
    ) -> URLRequest
}

@AISecureActor struct AISecureDefaultRequestBuilder: AISecureRequestBuilder {
    private let configuration: AISecureConfiguration

    nonisolated init(configuration: AISecureConfiguration) {
        self.configuration = configuration
    }

    func buildRequest(
        endpoint: String,
        body: Data,
        session: AISecureSession,
        service: AISecureServiceConfig
    ) -> URLRequest {
        var request = URLRequest(url: service.serviceURL.appendingPathComponent(endpoint))
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        sign(
            request: &request,
            body: body,
            service: service,
            session: session,
            endpoint: endpoint
        )

        return request
    }

    private func sign(
        request: inout URLRequest,
        body: Data,
        service: AISecureServiceConfig,
        session: AISecureSession,
        endpoint: String
    ) {
        let timestamp = String(Int(Date().timeIntervalSince1970))

        request.setValue(configuration.projectId, forHTTPHeaderField: "x-project-id")
        request.setValue(service.partialKey, forHTTPHeaderField: "x-partial-key")
        request.setValue(session.sessionToken, forHTTPHeaderField: "x-session-token")
        request.setValue(timestamp, forHTTPHeaderField: "x-timestamp")
        request.setValue(configuration.deviceFingerprint, forHTTPHeaderField: "x-device-fingerprint")
        request.setValue(service.provider, forHTTPHeaderField: "x-provider")

        // 🔴 CRITICAL: endpoint must include leading slash (Lambda uses "/v1/...")
        let normalizedEndpoint = endpoint.hasPrefix("/") ? endpoint : "/" + endpoint

        let bodyBase64 = body.base64EncodedString()
        let message = "\(timestamp):\(normalizedEndpoint):\(bodyBase64):\(session.sessionToken)"

        // ✅ MUST match Lambda: raw sessionToken as HMAC key
        let key = SymmetricKey(data: Data(session.sessionToken.utf8))

        let signature = HMAC<SHA256>.authenticationCode(
            for: Data(message.utf8),
            using: key
        )

        request.setValue(
            Data(signature).base64EncodedString(),
            forHTTPHeaderField: "x-signature"
        )

        logIf(.debug)?.debug("➡️ Request to \(endpoint)")
        let headers = request.allHTTPHeaderFields ?? [:]
        logIf(.debug)?.debug("Headers: \(headers)")
    }
}
