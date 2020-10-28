//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum UITestHelper {
    static var appGroupTarget: URL {
        if let appGroupIdentifier = Constants.appGroupIdentifier,
            let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        {
            return directory
        } else {
            fatalError("Unable to resolve path for ui test.")
        }
    }

    static var cacheTarget: URL {
        if let directory = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return directory
        } else {
            fatalError("Failed to resolve directory url for image cache.")
        }
    }

    public static func prepareData() {
        guard let appGroupSource = Bundle.main.url(forResource: "SnapshotSource", withExtension: nil)?.appendingPathComponent("AppGroupContainer") else { return }
        for fileName in (try? FileManager.default.contentsOfDirectory(atPath: appGroupSource.path)) ?? [String]() {
            let sourceUrl = appGroupSource.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: Self.appGroupTarget.appendingPathComponent(fileName))
            try? FileManager.default.copyItem(atPath: sourceUrl.path, toPath: Self.appGroupTarget.appendingPathComponent(fileName).path)
        }

        guard let cacheContainerSource = Bundle.main.url(forResource: "SnapshotSource", withExtension: nil)?.appendingPathComponent("CacheContainer") else { return }
        for fileName in (try? FileManager.default.contentsOfDirectory(atPath: cacheContainerSource.path)) ?? [String]() {
            let sourceUrl = cacheContainerSource.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: Self.appGroupTarget.appendingPathComponent(fileName))
            try? FileManager.default.copyItem(atPath: sourceUrl.path, toPath: Self.cacheTarget.appendingPathComponent(fileName).path)
        }
    }
}
