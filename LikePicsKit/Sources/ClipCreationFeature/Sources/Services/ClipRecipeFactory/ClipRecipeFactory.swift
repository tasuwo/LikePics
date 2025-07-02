//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

public protocol ClipRecipeFactoryProtocol {
    func make(url: URL?, hidesClip: Bool, partialRecipes: [ClipItemPartialRecipe], tagIds: [Tag.Identity], albumIds: Set<Album.Identity>) -> (ClipRecipe, [ImageContainer])
}

public struct ClipRecipeFactory {
    private let currentDateResolver: () -> Date
    private let uuidIssuer: () -> UUID

    public init(
        currentDateResolver: @escaping () -> Date,
        uuidIssuer: @escaping () -> UUID
    ) {
        self.currentDateResolver = currentDateResolver
        self.uuidIssuer = uuidIssuer
    }

    public init() {
        self.init(currentDateResolver: { Date() }, uuidIssuer: { UUID() })
    }
}

extension ClipRecipeFactory: ClipRecipeFactoryProtocol {
    // MARK: - ClipRecipeFactoryProtocol

    public func make(
        url: URL?,
        hidesClip: Bool,
        partialRecipes: [ClipItemPartialRecipe],
        tagIds: [Tag.Identity],
        albumIds: Set<Album.Identity>
    ) -> (ClipRecipe, [ImageContainer]) {
        let currentDate = self.currentDateResolver()
        let clipId = self.uuidIssuer()
        let itemAndContainers: [(ClipItemRecipe, ImageContainer)] = partialRecipes.map { partialRecipe in
            let imageId = self.uuidIssuer()
            let item = ClipItemRecipe(
                id: self.uuidIssuer(),
                url: url,
                clipId: clipId,
                imageId: imageId,
                partialRecipe: partialRecipe,
                currentDate: currentDate
            )
            let container = ImageContainer(id: imageId, data: partialRecipe.data)
            return (item, container)
        }
        let clip = ClipRecipe(
            clipId: clipId,
            isHidden: hidesClip,
            clipItems: itemAndContainers.map { $0.0 },
            tagIds: tagIds,
            albumIds: albumIds,
            dataSize: itemAndContainers.map({ $1.data.count }).reduce(0, +),
            registeredDate: currentDate,
            currentDate: currentDate
        )
        return (clip, itemAndContainers.map { $1 })
    }
}

extension ClipRecipe {
    fileprivate init(clipId: Clip.Identity, isHidden: Bool, clipItems: [ClipItemRecipe], tagIds: [Tag.Identity], albumIds: Set<Album.Identity>, dataSize: Int, registeredDate: Date, currentDate: Date) {
        self.init(
            id: clipId,
            description: nil,
            items: clipItems,
            tagIds: tagIds,
            albumIds: albumIds,
            isHidden: isHidden,
            dataSize: dataSize,
            registeredDate: registeredDate,
            updatedDate: currentDate
        )
    }
}

extension ClipItemRecipe {
    fileprivate init(id: ClipItem.Identity, url: URL?, clipId: Clip.Identity, imageId: ImageContainer.Identity, partialRecipe: ClipItemPartialRecipe, currentDate: Date) {
        self.init(
            id: id,
            url: url,
            clipId: clipId,
            clipIndex: partialRecipe.index,
            imageId: imageId,
            imageFileName: partialRecipe.fileName,
            imageUrl: partialRecipe.url,
            imageSize: ImageSize(height: partialRecipe.height, width: partialRecipe.width),
            imageDataSize: partialRecipe.data.count,
            registeredDate: currentDate,
            updatedDate: currentDate
        )
    }
}
