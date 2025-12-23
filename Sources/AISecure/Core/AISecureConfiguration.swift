//
//  AISecureConfiguration.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

public struct AISecureConfiguration: Sendable {
    let backendURL: URL
    let deviceFingerprint: String
    let service: AISecureServiceConfig

    init(
        backendURL: URL,
        deviceFingerprint: String,
        service: AISecureServiceConfig
    ) {
        self.backendURL = backendURL
        self.deviceFingerprint = deviceFingerprint
        self.service = service
    }
}
