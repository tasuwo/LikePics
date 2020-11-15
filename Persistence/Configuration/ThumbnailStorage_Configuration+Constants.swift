//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

extension ThumbnailStorage.Configuration {
    public static func resolve(for bundle: Bundle) -> ThumbnailStorage.Configuration {
        guard let bundleIdentifier = bundle.bundleIdentifier else {
            fatalError("Failed to resolve bundle identifier")
        }

        let targetUrl: URL = {
            let directoryName: String = "thumbnails"
            if let directory = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                return directory
                    .appendingPathComponent(bundleIdentifier, isDirectory: true)
                    .appendingPathComponent(directoryName, isDirectory: true)
            } else {
                fatalError("Failed to resolve directory url for image cache.")
            }
        }()

        return .init(targetUrl: targetUrl)
    }
}
