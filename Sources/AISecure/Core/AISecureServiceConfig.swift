//
//  AISecureServiceConfig.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

public struct AISecureServiceConfig: Sendable {
    public let provider: String
    public let serviceURL: URL
    public let partialKey: String

    public init(provider: String, serviceURL: String, partialKey: String) throws {
        guard !provider.isEmpty else {
            throw AISecureError.invalidConfiguration("Provider cannot be empty")
        }

        let trimmedURL = serviceURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: trimmedURL) else {
            throw AISecureError.invalidConfiguration("Invalid service URL: \(serviceURL)")
        }

        guard !partialKey.isEmpty else {
            throw AISecureError.invalidConfiguration("Partial key cannot be empty")
        }

        self.provider = provider
        self.serviceURL = url
        self.partialKey = partialKey
    }
}
