//
//  AISecureConfiguration.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

public struct AISecureConfiguration: Sendable {
    public let backendURL: URL
    public let deviceFingerprint: String
    public let service: AISecureServiceConfig

    public init(
        backendURL: URL,
        deviceFingerprint: String,
        service: AISecureServiceConfig
    ) {
        self.backendURL = backendURL
        self.deviceFingerprint = deviceFingerprint
        self.service = service
    }
}
