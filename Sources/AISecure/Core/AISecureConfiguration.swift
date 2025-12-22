//
//  AISecureConfiguration.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

public struct AISecureConfiguration: Sendable {
    let projectId: String
    let backendURL: URL
    let deviceFingerprint: String
    let services: [String: AISecureServiceConfig]

    init(
        projectId: String,
        backendURL: URL,
        deviceFingerprint: String,
        services: [AISecureServiceConfig]
    ) {
        self.projectId = projectId
        self.backendURL = backendURL
        self.deviceFingerprint = deviceFingerprint
        self.services = Dictionary(uniqueKeysWithValues: services.map { ($0.provider, $0) })
    }

    func service(for provider: String) -> AISecureServiceConfig? {
        return services[provider]
    }
}
