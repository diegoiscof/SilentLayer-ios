//
//  DeviceFingerprint.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation
import CryptoKit

#if canImport(UIKit)
import UIKit
#endif

struct DeviceFingerprint {
    @MainActor
    static func generate() -> String {
        #if canImport(UIKit)
        let vendorId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        let vendorId = UUID().uuidString
        #endif

        let hash = SHA256.hash(data: Data(vendorId.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
