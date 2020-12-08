//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

protocol ClipCollectionNavigationBarPresenterDataSource: AnyObject {
    func clipsCount(_ presenter: ClipCollectionNavigationBarPresenter) -> Int
    func selectedClipsCount(_ presenter: ClipCollectionNavigationBarPresenter) -> Int
}

protocol ClipCollectionNavigationBar: AnyObject {
    func setRightBarButtonItems(_ items: [ClipCollection.NavigationItem])
    func setLeftBarButtonItems(_ items: [ClipCollection.NavigationItem])
}

class ClipCollectionNavigationBarPresenter {
    private var operation: ClipCollection.Operation = .none {
        didSet {
            self.updateItems()
        }
    }

    private let context: ClipCollection.Context

    weak var dataSource: ClipCollectionNavigationBarPresenterDataSource?
    weak var navigationBar: ClipCollectionNavigationBar? {
        didSet {
            self.updateItems()
        }
    }

    // MARK: - Lifecycle

    init(context: ClipCollection.Context,
         dataSource: ClipCollectionNavigationBarPresenterDataSource)
    {
        self.context = context
        self.dataSource = dataSource
    }

    // MARK: - Methods

    func set(_ operation: ClipCollection.Operation) {
        self.operation = operation
    }

    func onUpdateSelection() {
        self.updateItems()
    }

    // MARK: Privates

    private func updateItems() {
        let isSelectedAll: Bool = {
            guard let dataSource = self.dataSource else { return false }
            return dataSource.clipsCount(self) <= dataSource.selectedClipsCount(self)
        }()
        let isSelectable: Bool = {
            guard let dataSource = self.dataSource else { return false }
            return dataSource.clipsCount(self) > 0
        }()
        let existsClips: Bool = {
            guard let dataSource = self.dataSource else { return false }
            return dataSource.clipsCount(self) > 1
        }()

        switch self.operation {
        case .none:
            self.navigationBar?.setRightBarButtonItems([
                context.isAlbum ? .reorder(isEnabled: existsClips) : nil,
                .select(isEnabled: isSelectable)
            ].compactMap { $0 })
            self.navigationBar?.setLeftBarButtonItems([])

        case .selecting:
            self.navigationBar?.setRightBarButtonItems([.cancel])
            self.navigationBar?.setLeftBarButtonItems([isSelectedAll ? .deselectAll : .selectAll])

        case .reordering:
            self.navigationBar?.setRightBarButtonItems([.done])
            self.navigationBar?.setLeftBarButtonItems([])
        }
    }
}
