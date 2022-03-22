//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

public extension TemporaryImageStorage.Configuration {
    enum Kind {
        case document
        case group
    }

    static func resolve(for bundle: Bundle, kind: Kind) -> Self {
        return .init(targetUrl: self.resolveUrl(for: bundle, kind: kind))
    }

    private static func resolveUrl(for bundle: Bundle, kind: Kind) -> URL {
        let directoryName = "images"

        guard let bundleIdentifier = bundle.bundleIdentifier else {
            fatalError("Failed to resolve bundle identifier")
        }

        switch kind {
        case .document:
            if let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                return directory
                    .appendingPathComponent(bundleIdentifier, isDirectory: true)
                    .appendingPathComponent(directoryName, isDirectory: true)
            } else {
                fatalError("Unable to resolve realm file url.")
            }

        case .group:
            guard let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.\(bundleIdentifier)") else {
                fatalError("Failed to resolve images containing directory url.")
            }
            return directory
                .appendingPathComponent(bundleIdentifier, isDirectory: true)
                .appendingPathComponent(directoryName, isDirectory: true)
        }
    }
}
