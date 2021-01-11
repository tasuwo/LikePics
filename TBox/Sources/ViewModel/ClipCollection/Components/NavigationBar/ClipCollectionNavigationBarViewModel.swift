//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

protocol ClipCollectionNavigationBarViewModelType {
    var inputs: ClipCollectionNavigationBarViewModelInputs { get }
    var outputs: ClipCollectionNavigationBarViewModelOutputs { get }
}

protocol ClipCollectionNavigationBarViewModelInputs {
    var clipsCount: CurrentValueSubject<Int, Never> { get }
    var selectedClipsCount: CurrentValueSubject<Int, Never> { get }
    var operation: CurrentValueSubject<ClipCollection.Operation, Never> { get }
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

    let clipsCount: CurrentValueSubject<Int, Never> = .init(0)
    let selectedClipsCount: CurrentValueSubject<Int, Never> = .init(0)
    let operation: CurrentValueSubject<ClipCollection.Operation, Never> = .init(.none)

    // MARK: ClipCollectionNavigationBarViewModelOutputs

    let leftItems: CurrentValueSubject<[ClipCollection.NavigationItem], Never> = .init([])
    let rightItems: CurrentValueSubject<[ClipCollection.NavigationItem], Never> = .init([])

    // MARK: Privates

    private let context: ClipCollection.Context
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init(context: ClipCollection.Context) {
        self.context = context

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
            .store(in: &self.subscriptions)
    }
}
