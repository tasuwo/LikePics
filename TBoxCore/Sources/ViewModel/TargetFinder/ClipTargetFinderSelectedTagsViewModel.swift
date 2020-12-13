//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

public protocol ClipTargetFinderSelectedTagsViewModelType {
    var inputs: ClipTargetFinderSelectedTagsViewModelInputs { get }
    var outputs: ClipTargetFinderSelectedTagsViewModelOutputs { get }
}

public protocol ClipTargetFinderSelectedTagsViewModelInputs {
    var delete: PassthroughSubject<Tag, Never> { get }
    var replace: PassthroughSubject<[Tag], Never> { get }
}

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

    public var delete: PassthroughSubject<Tag, Never> = .init()
    public var replace: PassthroughSubject<[Tag], Never> = .init()

    // MARK: ClipTargetFinderSelectedTagsViewModelOutputs

    public var tags: CurrentValueSubject<[Tag], Never> = .init([])

    // MARK: Privates

    public var cancellableBag: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    public init() {
        self.bind()
    }

    // MARK: - Methods

    private func bind() {
        // MARK: Inputs

        self.delete
            .sink { [weak self] tag in
                guard var newTags = self?.tags.value,
                    let index = newTags.firstIndex(of: tag) else { return }
                newTags.remove(at: index)
                self?.tags.send(newTags)
            }
            .store(in: &self.cancellableBag)

        self.replace
            .sink { [weak self] tags in
                self?.tags.send(tags)
            }
            .store(in: &self.cancellableBag)

        // MARK: Outputs
    }
}
