//
//  AISecureStorage.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation
import Security

final class AISecureStorage: Sendable {
    private let service = "com.aisecure.app"

    func saveSession(_ session: AISecureSession, for projectId: String) {
        guard let data = try? JSONEncoder().encode(session) else {
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: projectId,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            logIf(.error)?.error("[AISecureStorage] Failed to save session: \(status)")
        }
    }

    func getSession(for projectId: String) -> AISecureSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: projectId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let session = try? JSONDecoder().decode(AISecureSession.self, from: data) else {
            return nil
        }

        return session
    }

    func deleteSession(for projectId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: projectId
        ]

        SecItemDelete(query as CFDictionary)
    }

    func clearAllSessions() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        SecItemDelete(query as CFDictionary)
    }
}
