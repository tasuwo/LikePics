//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

extension ThumbnailStorage.Configuration {
    public static var cache: ThumbnailStorage.Configuration {
        let targetUrl: URL = {
            let directoryName: String = "thumbnails"
            if let directory = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
                return directory
                    .appendingPathComponent(Constants.bundleIdentifier, isDirectory: true)
                    .appendingPathComponent(directoryName, isDirectory: true)
            } else {
                fatalError("Failed to resolve directory url for image cache.")
            }
        }()
        return .init(targetUrl: targetUrl)
    }
}
