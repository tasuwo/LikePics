//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

protocol ClipCollectionToolBarViewModelType {
    var inputs: ClipCollectionToolBarViewModelInputs { get }
    var outputs: ClipCollectionToolBarViewModelOutputs { get }
}

protocol ClipCollectionToolBarViewModelInputs {
    var selectedClipsCount: PassthroughSubject<Int, Never> { get }
    var operation: PassthroughSubject<ClipCollection.Operation, Never> { get }
}

protocol ClipCollectionToolBarViewModelOutputs {
    var isHidden: CurrentValueSubject<Bool, Never> { get }
    var items: CurrentValueSubject<[ClipCollection.ToolBarItem], Never> { get }
    var selectionCount: CurrentValueSubject<Int, Never> { get }
}

class ClipCollectionToolBarViewModel: ClipCollectionToolBarViewModelType,
    ClipCollectionToolBarViewModelInputs,
    ClipCollectionToolBarViewModelOutputs
{
    // MARK: - Properties

    // MARK: ClipCollectionToolBarViewModelType

    var inputs: ClipCollectionToolBarViewModelInputs { self }
    var outputs: ClipCollectionToolBarViewModelOutputs { self }

    // MARK: ClipCollectionToolBarViewModelInputs

    var selectedClipsCount: PassthroughSubject<Int, Never> = .init()
    var operation: PassthroughSubject<ClipCollection.Operation, Never> = .init()

    // MARK: ClipCollectionToolBarViewModelOutputs

    var isHidden: CurrentValueSubject<Bool, Never> = .init(false)
    var items: CurrentValueSubject<[ClipCollection.ToolBarItem], Never> = .init([])
    var selectionCount: CurrentValueSubject<Int, Never> = .init(0)

    // MARK: Privates

    private let context: ClipCollection.Context
    private var cancellableBag: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init(context: ClipCollection.Context) {
        self.context = context

        // MARK: Bind

        self.selectedClipsCount
            .sink { [weak self] count in self?.selectionCount.send(count) }
            .store(in: &self.cancellableBag)

        self.operation
            .map { $0.isEditing }
            .sink { [weak self] isEditing in self?.isHidden.send(!isEditing) }
            .store(in: &self.cancellableBag)

        self.items.send([
            .add,
            .spacer,
            .hide,
            .spacer,
            .unhide,
            .spacer,
            self.context.isAlbum ? .removeFromAlbum : .delete
        ])
    }
}
