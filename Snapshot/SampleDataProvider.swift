//
//  SampleDataProvider.swift
//  Snapshot
//
//  Created by Tasuku Tozawa on 2022/03/21.
//

import Domain
import TestHelper
import UIKit

enum SampleDataSetProvider {
    static var clips: [Clip] = (1..<30).map {
        let imageName = String(format: "%03d", $0)
        let imageData = UIImage(named: imageName)!.jpegData(compressionQuality: 1)!
        let size = SampleDataSetProvider.resolveSize(for: imageData)!

        let clipId = UUID()
        return Clip.makeDefault(
            id: clipId,
            items: [
                ClipItem.makeDefault(
                    id: UUID(),
                    clipId: clipId,
                    imageId: UUID(),
                    imageFileName: imageName,
                    imageSize: ImageSize(height: size.height, width: size.width),
                    imageDataSize: 1024 * 15,
                    registeredDate: Date(),
                    updatedDate: Date()
                )
            ]
        )
    }

    static var tags: [Tag] = {
        return [
            .makeDefault(name: NSLocalizedString("tag_01", comment: ""), clipCount: 1),
            .makeDefault(name: NSLocalizedString("tag_02", comment: ""), clipCount: 2),
            .makeDefault(name: NSLocalizedString("tag_03", comment: ""), clipCount: 2),
            .makeDefault(name: NSLocalizedString("tag_04", comment: ""), clipCount: 2),
            .makeDefault(name: NSLocalizedString("tag_05", comment: ""), clipCount: 3),
            .makeDefault(name: NSLocalizedString("tag_06", comment: ""), clipCount: 5),
        ]
    }()

    static var albums: [Album] = {
        return [
            .makeDefault(
                title: NSLocalizedString("album_01", comment: ""),
                clips: [
                    Self.clips[21],
                    Self.clips[21],
                    Self.clips[21],
                    Self.clips[21],
                    Self.clips[21],
                ]
            ),
            .makeDefault(
                title: NSLocalizedString("album_02", comment: ""),
                clips: [
                    Self.clips[3],
                    Self.clips[3],
                    Self.clips[3],
                    Self.clips[3],
                ]
            ),
        ]
    }()

    static func clip(for id: UUID) -> Clip? {
        return self.clips.first(where: { $0.id == id })
    }

    static func clipItem(for id: UUID) -> ClipItem? {
        return self.clips.first(where: { $0.items.first(where: { item in item.id == id }) != nil })?.items.first
    }

    static func image(for id: UUID) -> Data? {
        guard let imageName = self.clips.first(where: { $0.items.first(where: { item in item.imageId == id }) != nil })?.items.first?.imageFileName else { return nil }
        return UIImage(named: imageName)?.pngData()
    }

    private static func resolveSize(for data: Data) -> CGSize? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else { return nil }
        return self.resolveSize(for: imageSource)
    }

    private static func resolveSize(for imageSource: CGImageSource) -> CGSize? {
        guard
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?,
            let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
            let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
        else {
            return nil
        }
        let orientation: CGImagePropertyOrientation? = {
            guard let number = imageProperties[kCGImagePropertyOrientation] as? UInt32 else { return nil }
            return CGImagePropertyOrientation(rawValue: number)
        }()
        switch orientation {
        case .up, .upMirrored, .down, .downMirrored, .none:
            return CGSize(width: pixelWidth, height: pixelHeight)

        case .left, .leftMirrored, .right, .rightMirrored:
            return CGSize(width: pixelHeight, height: pixelWidth)
        }
    }
}
