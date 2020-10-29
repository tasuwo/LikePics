//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum Constants {
    static var appGroupIdentifier: String? {
        return "group.net.tasuwo.TBox"
    }

    public static var imageStorageConfiguration: ImageStorage.Configuration {
        let targetUrl: URL = {
            let directoryName: String = "TBoxImages"
            guard let appGroupIdentifier = Constants.appGroupIdentifier,
                let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            else {
                fatalError("Failed to resolve images containing directory url.")
            }
            return directory.appendingPathComponent(directoryName, isDirectory: true)
        }()
        return .init(targetUrl: targetUrl)
    }
}
