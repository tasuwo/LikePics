//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

public protocol ClipBuildable {
    func build(url: URL?, hidesClip: Bool, sources: [ClipItemSource], tagIds: [Tag.Identity]) -> (ClipRecipe, [ImageContainer])
}

public struct ClipBuilder {
    private let currentDateResolver: () -> Date
    private let uuidIssuer: () -> UUID

    public init(currentDateResolver: @escaping () -> Date,
                uuidIssuer: @escaping () -> UUID)
    {
        self.currentDateResolver = currentDateResolver
        self.uuidIssuer = uuidIssuer
    }

    public init() {
        self.init(currentDateResolver: { Date() }, uuidIssuer: { UUID() })
    }
}

extension ClipBuilder: ClipBuildable {
    // MARK: - ClipBuildable

    public func build(url: URL?,
                      hidesClip: Bool,
                      sources: [ClipItemSource],
                      tagIds: [Tag.Identity]) -> (ClipRecipe, [ImageContainer])
    {
        let currentDate = self.currentDateResolver()
        let clipId = self.uuidIssuer()
        let itemAndContainers: [(ClipItemRecipe, ImageContainer)] = sources.map { source in
            let imageId = self.uuidIssuer()
            let item = ClipItemRecipe(id: self.uuidIssuer(),
                                      url: url,
                                      clipId: clipId,
                                      index: source.index,
                                      imageId: imageId,
                                      imageDataSize: source.data.count,
                                      source: source,
                                      currentDate: currentDate)
            let container = ImageContainer(id: imageId, data: source.data)
            return (item, container)
        }
        let clip = ClipRecipe(clipId: clipId,
                              isHidden: hidesClip,
                              clipItems: itemAndContainers.map { $0.0 },
                              tagIds: tagIds,
                              dataSize: itemAndContainers.map({ $1.data.count }).reduce(0, +),
                              registeredDate: currentDate,
                              currentDate: currentDate)
        return (clip, itemAndContainers.map { $1 })
    }
}

private extension ClipRecipe {
    init(clipId: Clip.Identity, isHidden: Bool, clipItems: [ClipItemRecipe], tagIds: [Tag.Identity], dataSize: Int, registeredDate: Date, currentDate: Date) {
        self.init(id: clipId,
                  description: nil,
                  items: clipItems,
                  tagIds: tagIds,
                  isHidden: isHidden,
                  dataSize: dataSize,
                  registeredDate: registeredDate,
                  updatedDate: currentDate)
    }
}

private extension ClipItemRecipe {
    init(id: ClipItem.Identity, url: URL?, clipId: Clip.Identity, index: Int, imageId: ImageContainer.Identity, imageDataSize: Int, source: ClipItemSource, currentDate: Date) {
        self.init(id: id,
                  url: url,
                  clipId: clipId,
                  clipIndex: index,
                  imageId: imageId,
                  imageFileName: source.fileName,
                  imageUrl: source.url,
                  imageSize: ImageSize(height: source.height, width: source.width),
                  imageDataSize: imageDataSize,
                  registeredDate: currentDate,
                  updatedDate: currentDate)
    }
}
