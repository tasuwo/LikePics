//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

public protocol ClipTargetFinderSelectedTagsViewModelType {
    var inputs: ClipTargetFinderSelectedTagsViewModelInputs { get }
    var outputs: ClipTargetFinderSelectedTagsViewModelOutputs { get }
}

public protocol ClipTargetFinderSelectedTagsViewModelInputs {}

public protocol ClipTargetFinderSelectedTagsViewModelOutputs {
    var tags: CurrentValueSubject<[Tag], Never> { get }
}

public class ClipTargetFinderSelectedTagsViewModel: ClipTargetFinderSelectedTagsViewModelType,
    ClipTargetFinderSelectedTagsViewModelInputs,
    ClipTargetFinderSelectedTagsViewModelOutputs
{
    // MARK: - Properties

    // MARK: ClipTargetFinderSelectedTagsViewModelType

    public var inputs: ClipTargetFinderSelectedTagsViewModelInputs { self }
    public var outputs: ClipTargetFinderSelectedTagsViewModelOutputs { self }

    // MARK: ClipTargetFinderSelectedTagsViewModelInputs

    // MARK: ClipTargetFinderSelectedTagsViewModelOutputs

    public var tags: CurrentValueSubject<[Tag], Never> = .init([])

    public init() {
        self.bind()
    }

    // MARK: - Methods

    private func bind() {
        self.tags.send([.init(id: UUID(), name: "hoge")])
    }
}
