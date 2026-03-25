//
//  ChessEngineFramework.swift
//  ChessEngineFramework
//
//  Created by Steve Wart on 2025-07-23.
//

import Foundation

/// Exposes version metadata from the ChessEngine framework bundle.
/// Clients should use this rather than reading Bundle.main or any plist directly.
public class ChessEngineInfo: NSObject {

    private static var bundle: Bundle {
        // Look up by bundle identifier — reliable regardless of which binary
        // the class ends up in (e.g. if the file is also compiled into the tool).
        Bundle(identifier: "com.mandeluna.ChessEngineFramework") ?? Bundle(for: ChessEngineInfo.self)
    }
    public static var displayName: String {
        bundle.infoDictionary?["CFBundleDisplayName"] as? String ?? "Chamonix"
    }
    public static var version: String {
        bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }
    public static var buildNumber: String {
        bundle.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }
    public static var author: String {
        bundle.infoDictionary?["NSHumanReadableCopyright"] as? String ?? ""
    }
}

