//
//  DeviceFingerprint.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation
import Security

public enum DeviceIdentifier {

    private static let service = "com.aisecure.device"
    private static let account = "device-id"

    public static func get() -> String {
        if let existing = try? load() {
            return existing
        }

        let newID = UUID().uuidString
        try? save(newID)
        return newID
    }

    private static func save(_ id: String) throws {
        let data = Data(id.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        // 1. Delete existing item using only identifying attributes
        SecItemDelete(query as CFDictionary)

        // 2. Setup new attributes to add
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AISecureError.invalidConfiguration("Keychain Save Error: \(status)")
        }
    }

    private static func load() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess,
              let data = result as? Data,
              let id = String(data: data, encoding: .utf8) else {
            return nil
        }

        return id
    }
}
