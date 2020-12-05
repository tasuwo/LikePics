//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

protocol ClipCollectionNavigationBarPresenterDataSource: AnyObject {
    func isReorderable(_ presenter: ClipCollectionNavigationBarPresenter) -> Bool
    func clipsCount(_ presenter: ClipCollectionNavigationBarPresenter) -> Int
    func selectedClipsCount(_ presenter: ClipCollectionNavigationBarPresenter) -> Int
}

protocol ClipCollectionNavigationBar: AnyObject {
    func setRightBarButtonItems(_ items: [ClipCollection.NavigationItem])
    func setLeftBarButtonItems(_ items: [ClipCollection.NavigationItem])
}

class ClipCollectionNavigationBarPresenter {
    enum State {
        case `default`
        case selecting
        case reordering

        var isEditing: Bool {
            switch self {
            case .selecting, .reordering:
                return true

            case .default:
                return false
            }
        }
    }

    private var state: State = .default {
        didSet {
            self.updateItems()
        }
    }

    weak var dataSource: ClipCollectionNavigationBarPresenterDataSource?
    weak var navigationBar: ClipCollectionNavigationBar? {
        didSet {
            self.updateItems()
        }
    }

    // MARK: - Lifecycle

    init(dataSource: ClipCollectionNavigationBarPresenterDataSource) {
        self.dataSource = dataSource
    }

    // MARK: - Methods

    func set(_ state: State) {
        self.state = state
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
        let isReorderable: Bool = {
            guard let dataSource = self.dataSource else { return false }
            return dataSource.clipsCount(self) > 1
        }()

        switch self.state {
        case .default:
            self.navigationBar?.setRightBarButtonItems([
                (self.dataSource?.isReorderable(self) ?? false) ? .reorder(isEnabled: isReorderable) : nil,
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
