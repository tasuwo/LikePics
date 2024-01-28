//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import Foundation

struct ImageSourcesSnapshot: Equatable {
    var order: [UUID]
    var selections: [UUID]
    var imageSourceById: [UUID: ImageSource]

    // MARK: - Initializers

    init(order: [UUID], selections: [UUID], imageSourceById: [UUID: ImageSource]) {
        self.order = order
        self.selections = selections
        self.imageSourceById = imageSourceById
    }

    init(_ imageSources: [ImageSource], selectAll: Bool) {
        self.order = imageSources.map { $0.identifier }
        self.selections = selectAll ? imageSources.map { $0.identifier } : []
        self.imageSourceById = imageSources.reduce(into: [UUID: ImageSource](), { $0[$1.identifier] = $1 })
    }

    // MARK: - Methods

    func selected(_ id: UUID) -> Self {
        return .init(order: order,
                     selections: selections + [id],
                     imageSourceById: imageSourceById)
    }

    func deselected(_ id: UUID) -> Self {
        return .init(order: order,
                     selections: selections.filter { $0 != id },
                     imageSourceById: imageSourceById)
    }

    func removed(_ id: UUID) -> Self {
        var new = self
        new.order.removeAll(where: { $0 == id })
        new.selections.removeAll(where: { $0 == id })
        new.imageSourceById.removeValue(forKey: id)
        return new
    }
}
