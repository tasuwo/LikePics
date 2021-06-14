//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

struct ImageSourcesSnapshot: Equatable {
    let order: [UUID]
    let selections: [UUID]
    let imageSourceById: [UUID: ImageSource]

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
}
