//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

protocol ClipCollectionNavigationBarViewModelType {
    var inputs: ClipCollectionNavigationBarViewModelInputs { get }
    var outputs: ClipCollectionNavigationBarViewModelOutputs { get }
}

protocol ClipCollectionNavigationBarViewModelInputs {
    var clipsCount: PassthroughSubject<Int, Never> { get }
    var selectedClipsCount: PassthroughSubject<Int, Never> { get }
    var operation: PassthroughSubject<ClipCollection.Operation, Never> { get }
}

protocol ClipCollectionNavigationBarViewModelOutputs {
    var leftItems: CurrentValueSubject<[ClipCollection.NavigationItem], Never> { get }
    var rightItems: CurrentValueSubject<[ClipCollection.NavigationItem], Never> { get }
}

class ClipCollectionNavigationBarViewModel: ClipCollectionNavigationBarViewModelType,
    ClipCollectionNavigationBarViewModelInputs,
    ClipCollectionNavigationBarViewModelOutputs
{
    // MARK: - Properties

    // MARK: ClipCollectionNavigationBarViewModelType

    var inputs: ClipCollectionNavigationBarViewModelInputs { self }
    var outputs: ClipCollectionNavigationBarViewModelOutputs { self }

    // MARK: ClipCollectionNavigationBarViewModelInputs

    let clipsCount: PassthroughSubject<Int, Never>
    let selectedClipsCount: PassthroughSubject<Int, Never>
    let operation: PassthroughSubject<ClipCollection.Operation, Never>

    // MARK: ClipCollectionNavigationBarViewModelOutputs

    let leftItems: CurrentValueSubject<[ClipCollection.NavigationItem], Never>
    let rightItems: CurrentValueSubject<[ClipCollection.NavigationItem], Never>

    // MARK: Privates

    private let context: ClipCollection.Context
    private var cancellableBag: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init(context: ClipCollection.Context) {
        self.context = context

        // MARK: Inputs

        self.operation = .init()
        self.clipsCount = .init()
        self.selectedClipsCount = .init()

        // MARK: Outputs

        self.leftItems = .init([])
        self.rightItems = .init([])

        // MARK: Bind

        self.operation
            .combineLatest(self.clipsCount, self.selectedClipsCount)
            .sink { [weak self] mode, clipsCount, selectedCount in
                let isSelectedAll: Bool = clipsCount <= selectedCount
                let isSelectable: Bool = clipsCount > 0
                let existsClips: Bool = clipsCount > 1

                switch mode {
                case .none:
                    self?.rightItems.send([
                        context.isAlbum ? .reorder(isEnabled: existsClips) : nil,
                        .select(isEnabled: isSelectable)
                    ].compactMap { $0 })
                    self?.leftItems.send([])

                case .selecting:
                    self?.rightItems.send([.cancel])
                    self?.leftItems.send([isSelectedAll ? .deselectAll : .selectAll])

                case .reordering:
                    self?.rightItems.send([.done])
                    self?.leftItems.send([])
                }
            }
            .store(in: &self.cancellableBag)
    }
}
