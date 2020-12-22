//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipBuildable {
    func build(sources: [ClipItemSource], tags: [Tag]) -> (Clip, [ImageContainer])
}

struct ClipBuilder {
    private let url: URL?
    private let currentDateResolver: () -> Date
    private let uuidIssuer: () -> UUID

    init(url: URL?,
         currentDateResolver: @escaping () -> Date,
         uuidIssuer: @escaping () -> UUID)
    {
        self.url = url
        self.currentDateResolver = currentDateResolver
        self.uuidIssuer = uuidIssuer
    }
}

extension ClipBuilder: ClipBuildable {
    // MARK: - ClipBuildable

    func build(sources: [ClipItemSource], tags: [Tag]) -> (Clip, [ImageContainer]) {
        let currentDate = self.currentDateResolver()
        let clipId = self.uuidIssuer()
        let itemAndContainers: [(ClipItem, ImageContainer)] = sources.map { source in
            let imageId = self.uuidIssuer()
            let item = ClipItem(id: self.uuidIssuer(),
                                url: self.url,
                                clipId: clipId,
                                index: source.index,
                                imageId: imageId,
                                imageDataSize: source.data.count,
                                source: source,
                                currentDate: currentDate)
            let container = ImageContainer(id: imageId, data: source.data)
            return (item, container)
        }
        let clip = Clip(clipId: clipId,
                        clipItems: itemAndContainers.map { $0.0 },
                        tags: tags,
                        dataSize: itemAndContainers.map({ $1.data.count }).reduce(0, +),
                        registeredDate: currentDate,
                        currentDate: currentDate)
        return (clip, itemAndContainers.map { $1 })
    }
}

private extension Clip {
    init(clipId: Clip.Identity, clipItems: [ClipItem], tags: [Tag], dataSize: Int, registeredDate: Date, currentDate: Date) {
        self.init(id: clipId,
                  description: nil,
                  items: clipItems,
                  tags: tags,
                  isHidden: false,
                  dataSize: dataSize,
                  registeredDate: registeredDate,
                  updatedDate: currentDate)
    }
}

private extension ClipItem {
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
