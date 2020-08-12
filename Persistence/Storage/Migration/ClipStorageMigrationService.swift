//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

enum ClipStorageMigrationService {
    static let migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
        if oldSchemaVersion < 1 {
            Self.migrationToV1(migration)
        }
    }

    // MARK: Migration to V1

    private static func migrationToV1(_ migration: Migration) {
        migration.enumerateObjects(ofType: ClipObject.className()) { oldObject, newObject in
            let clipUrl = oldObject!["url"] as! String

            newObject!["descriptionText"] = nil

            let webImages = oldObject!["webImages"] as! List<MigrationObject>
            webImages.enumerated().forEach { index, webImage in
                let largeImageUrlString = webImage["url"] as! String
                let largeImageData = webImage["image"] as! Data

                // ClippedImage for large image

                let clippedLargeImage = ClippedImageObject()
                clippedLargeImage.clipUrl = clipUrl
                clippedLargeImage.imageUrl = largeImageUrlString
                clippedLargeImage.image = largeImageData
                clippedLargeImage.key = clippedLargeImage.makeKey()
                migration.create(ClippedImageObject.className(), value: clippedLargeImage)

                // ClippedImage for thumbnail

                let thumbnailClippedImage = ClippedImageObject()

                thumbnailClippedImage.clipUrl = clipUrl

                let thumbnailImageUrlString = Self.resolveThumbnailImageUrlString(fromUrlString: largeImageUrlString)
                thumbnailClippedImage.imageUrl = thumbnailImageUrlString

                let thumbnailImageData = try! Data(contentsOf: URL(string: thumbnailImageUrlString)!)
                thumbnailClippedImage.image = UIImage(data: thumbnailImageData)!.pngData()!

                thumbnailClippedImage.key = thumbnailClippedImage.makeKey()

                migration.create(ClippedImageObject.className(), value: thumbnailClippedImage)

                // ClipItem

                let thumbnailImageSize = Self.calcImageSize(ofUrl: URL(string: thumbnailImageUrlString)!)
                let largeImageSize = Self.calcImageSize(ofUrl: URL(string: largeImageUrlString)!)

                let clipItem = ClipItemObject()
                clipItem.clipUrl = clipUrl
                clipItem.clipIndex = index
                clipItem.thumbnailImageUrl = thumbnailImageUrlString
                clipItem.thumbnailHeight = Double(thumbnailImageSize.height)
                clipItem.thumbnailWidth = Double(thumbnailImageSize.width)
                clipItem.largeImageUrl = largeImageUrlString
                clipItem.largeImageHeight = Double(largeImageSize.height)
                clipItem.largeImageWidth = Double(largeImageSize.width)
                clipItem.key = clipItem.makeKey()

                let createdClipItem = migration.create(ClipItemObject.className(), value: clipItem)

                (newObject!["items"]! as! List<MigrationObject>).append(createdClipItem)
            }
        }
        migration.deleteData(forType: "WebImageObject")
    }

    private static func resolveThumbnailImageUrlString(fromUrlString url: String) -> String {
        guard url.contains("twimg") else { return url }
        guard var components = URLComponents(string: url), let queryItems = components.queryItems else {
            return url
        }

        let newQueryItems: [URLQueryItem] = queryItems
            .compactMap { queryItem in
                guard queryItem.name == "name" else { return queryItem }
                return URLQueryItem(name: "name", value: "small")
            }

        components.queryItems = newQueryItems

        return components.url?.absoluteString ?? url
    }

    private static func calcImageSize(ofUrl url: URL) -> CGSize {
        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) {
            if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary? {
                let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as! CGFloat
                let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as! CGFloat
                return .init(width: pixelWidth, height: pixelHeight)
            }
        }
        return .zero
    }
}

// MARK: - Legacy Realm Objects

final class WebImageObject: Object {
    @objc dynamic var url: String = ""
    @objc dynamic var image: Data = Data()
}
