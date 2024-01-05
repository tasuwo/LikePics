//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import Foundation

struct ImageLoadSourcesSnapshot: Equatable {
    let order: [UUID]
    let selections: [UUID]
    let imageLoadSourceById: [UUID: ImageLoadSource]

    // MARK: - Initializers

    init(order: [UUID], selections: [UUID], imageSourceById: [UUID: ImageLoadSource]) {
        self.order = order
        self.selections = selections
        self.imageLoadSourceById = imageSourceById
    }

    init(_ imageSources: [ImageLoadSource], selectAll: Bool) {
        self.order = imageSources.map { $0.identifier }
        self.selections = selectAll ? imageSources.map { $0.identifier } : []
        self.imageLoadSourceById = imageSources.reduce(into: [UUID: ImageLoadSource](), { $0[$1.identifier] = $1 })
    }

    // MARK: - Methods

    func selected(_ id: UUID) -> Self {
        return .init(order: order,
                     selections: selections + [id],
                     imageSourceById: imageLoadSourceById)
    }

    func deselected(_ id: UUID) -> Self {
        return .init(order: order,
                     selections: selections.filter { $0 != id },
                     imageSourceById: imageLoadSourceById)
    }
}
