//
//  AISecureSession.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

struct AISecureSession: Codable, Sendable {
    let sessionToken: String
    let expiresAt: TimeInterval

    var isExpired: Bool {
        let nowMillis = Date().timeIntervalSince1970 * 1000
        return expiresAt <= nowMillis
    }
}
