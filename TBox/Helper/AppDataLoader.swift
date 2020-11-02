//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

enum AppDataLoader {
    static func loadAppData() {
        let contentsURL: URL
        switch Locale.autoupdatingCurrent.languageCode {
        case "ja":
            guard let url = Bundle.main.url(forResource: "AppData/ja-JP", withExtension: nil) else { return }
            contentsURL = url

        case "en":
            guard let url = Bundle.main.url(forResource: "AppData/en-US", withExtension: nil) else { return }
            contentsURL = url

        default:
            fatalError("Unexpected languageCode: \(Locale.autoupdatingCurrent.languageCode ?? "nil")")
        }

        guard let destinationRoot = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).last?.deletingLastPathComponent() else {
            return
        }

        guard let enumerator = Foundation.FileManager.default.enumerator(at: contentsURL, includingPropertiesForKeys: [.isDirectoryKey], options: [], errorHandler: nil) else {
            return
        }

        while let sourceURL = enumerator.nextObject() as? URL {
            guard let resourceValues = try? sourceURL.resourceValues(forKeys: [.isDirectoryKey]),
                let isDirectory = resourceValues.isDirectory,
                !isDirectory
            else {
                continue
            }

            let path = sourceURL.standardizedFileURL.path.replacingOccurrences(of: contentsURL.standardizedFileURL.path, with: "")
            let destinationURL = destinationRoot.appendingPathComponent(path)

            try? FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            try? FileManager.default.removeItem(at: destinationURL)
            try? FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        }
    }
}
