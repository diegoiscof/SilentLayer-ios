//
//  DeviceMetadata.swift
//  AISecure
//
//  Created by Diego Francisco Oruna Cabrera on 22/12/25.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

public struct DeviceMetadata {
    @MainActor
    static func generateMetadataString(partialKey: String) -> String {
        let version = "1"
        let timestamp = String(Int(Date().timeIntervalSince1970))

        #if canImport(UIKit)
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let systemName = UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        #else
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let systemName = "macOS"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let deviceModel = "Mac"
        #endif

        let sdkVersion = AISecure.sdkVersion
        let bodySize = "0" // Can be populated with actual request body size if needed

        // Format: version|bundleID|appVersion|sdkVersion|timestamp|systemName|osVersion|deviceModel|bodySize|partialKey
        let components = [
            version,
            bundleID,
            appVersion,
            sdkVersion,
            timestamp,
            systemName,
            osVersion,
            deviceModel,
            bodySize,
            partialKey
        ]

        return components.joined(separator: "|")
    }
}
