//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import Foundation

struct ImageSourcesSnapshot: Equatable {
    let order: [UUID]
    let selections: [UUID]
    let ImageSourceById: [UUID: ImageSource]

    // MARK: - Initializers

    init(order: [UUID], selections: [UUID], imageSourceById: [UUID: ImageSource]) {
        self.order = order
        self.selections = selections
        self.ImageSourceById = imageSourceById
    }

    init(_ imageSources: [ImageSource], selectAll: Bool) {
        self.order = imageSources.map { $0.identifier }
        self.selections = selectAll ? imageSources.map { $0.identifier } : []
        self.ImageSourceById = imageSources.reduce(into: [UUID: ImageSource](), { $0[$1.identifier] = $1 })
    }

    // MARK: - Methods

    func selected(_ id: UUID) -> Self {
        return .init(order: order,
                     selections: selections + [id],
                     imageSourceById: ImageSourceById)
    }

    func deselected(_ id: UUID) -> Self {
        return .init(order: order,
                     selections: selections.filter { $0 != id },
                     imageSourceById: ImageSourceById)
    }
}
