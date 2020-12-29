//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import UIKit

public protocol ThumbnailLoaderProtocol {
    func readCache(for item: ClipItem) -> UIImage?
    func load(for item: ClipItem, pointSize: CGSize, scale: CGFloat) -> Future<UIImage?, Never>
    func delete(for item: ClipItem)
}

public class ThumbnailLoader {
    // MARK: - Properties

    private let queryService: NewImageQueryServiceProtocol
    private let thumbnailStorage: ThumbnailStorageProtocol
    private let fileManager: FileManager
    private let logger: TBoxLoggable
    private let cache = NSCache<NSString, AnyObject>()

    // MARK: - Lifecycle

    public init(queryService: NewImageQueryServiceProtocol,
                thumbnailStorage: ThumbnailStorageProtocol,
                fileManager: FileManager = .default,
                logger: TBoxLoggable = RootLogger.shared) throws
    {
        self.queryService = queryService
        self.thumbnailStorage = thumbnailStorage
        self.fileManager = fileManager
        self.logger = logger

        self.cache.countLimit = 100
    }

    // MARK: - Methods

    private func readDiskCache(for item: ClipItem) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: true] as CFDictionary
        guard let url = self.thumbnailStorage.resolveImageUrl(for: item),
            let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions),
            let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    private func thumbnail(for item: ClipItem, pointSize: CGSize, scale: CGFloat) -> CGImage? {
        guard let data = try? self.queryService.read(having: item.imageId) else {
            self.logger.write(ConsoleLog(level: .debug, message: """
            元画像ファイルの取得に失敗しました。iCloud同期前である可能性があります (item=\(item.id), name=\(item.imageFileName)
            """))
            return nil
        }

        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            self.logger.write(ConsoleLog(level: .debug, message: """
            サムネイル生成のためのCGImageSourceの生成に失敗しました。 (item=\(item.id), name=\(item.imageFileName)
            """))
            return nil
        }

        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else {
            self.logger.write(ConsoleLog(level: .debug, message: """
            サムネイルの生成に失敗しました。 (item=\(item.id), name=\(item.imageFileName)
            """))
            return nil
        }

        return downsampledImage
    }
}

extension ThumbnailLoader: ThumbnailLoaderProtocol {
    // MARK: - ThumbnailLoaderProtocol

    public func readCache(for item: ClipItem) -> UIImage? {
        // メモリキャッシュを探す
        if let cachedImage = self.cache.object(forKey: item.id.uuidString as NSString) as? UIImage {
            return cachedImage
        }

        // ディスクキャッシュを探す
        if let cachedImage = self.readDiskCache(for: item) {
            // メモリキャッシュを更新する
            self.cache.setObject(cachedImage, forKey: item.id.uuidString as NSString)
            return cachedImage
        }

        return nil
    }

    public func load(for item: ClipItem, pointSize: CGSize, scale: CGFloat) -> Future<UIImage?, Never> {
        return Future { [weak self] promise in
            // メモリキャッシュを探す
            if let cachedImage = self?.cache.object(forKey: item.id.uuidString as NSString) as? UIImage {
                promise(.success(cachedImage))
                return
            }

            // ディスクキャッシュを探す
            if let cachedImage = self?.readDiskCache(for: item) {
                // メモリキャッシュを更新する
                self?.cache.setObject(cachedImage, forKey: item.id.uuidString as NSString)
                promise(.success(cachedImage))
                return
            }

            // キャッシュミスした場合、サムネイルを新規作成
            guard let cgImage = self?.thumbnail(for: item, pointSize: pointSize, scale: scale) else {
                promise(.success(nil))
                return
            }
            // ディスクキャッシュを更新する
            _ = self?.thumbnailStorage.save(cgImage, for: item)
            // メモリキャッシュを更新する
            let image = UIImage(cgImage: cgImage)
            self?.cache.setObject(image, forKey: item.id.uuidString as NSString)

            promise(.success(image))
        }
    }

    public func delete(for item: ClipItem) {
        self.cache.removeObject(forKey: item.id.uuidString as NSString)
        _ = self.thumbnailStorage.delete(for: item)
    }
}
