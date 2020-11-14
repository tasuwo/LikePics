//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

extension ImageStorage.Configuration {
    public static var document: ImageStorage.Configuration {
        let targetUrl: URL = {
            let directoryName: String = "images"
            if let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                return directory
                    .appendingPathComponent(Constants.bundleIdentifier, isDirectory: true)
                    .appendingPathComponent(directoryName, isDirectory: true)
            } else {
                fatalError("Unable to resolve realm file url.")
            }
        }()
        return .init(targetUrl: targetUrl)
    }

    public static var group: ImageStorage.Configuration {
        let targetUrl: URL = {
            let directoryName: String = "images"
            guard let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier) else {
                fatalError("Failed to resolve images containing directory url.")
            }
            return directory
                .appendingPathComponent(Constants.bundleIdentifier, isDirectory: true)
                .appendingPathComponent(directoryName, isDirectory: true)
        }()
        return .init(targetUrl: targetUrl)
    }
}