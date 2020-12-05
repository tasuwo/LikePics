//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

protocol ClipsListNavigationPresenterDataSource: AnyObject {
    func isReorderable(_ presenter: ClipsListNavigationItemsPresenter) -> Bool
    func clipsCount(_ presenter: ClipsListNavigationItemsPresenter) -> Int
    func selectedClipsCount(_ presenter: ClipsListNavigationItemsPresenter) -> Int
}

protocol ClipsListNavigationBar: AnyObject {
    func setRightBarButtonItems(_ items: [ClipsListNavigationItemsPresenter.Item])
    func setLeftBarButtonItems(_ items: [ClipsListNavigationItemsPresenter.Item])
}

class ClipsListNavigationItemsPresenter {
    enum Item {
        case cancel
        case selectAll
        case deselectAll
        case select(isEnabled: Bool)
        case reorder(isEnabled: Bool)
        case done

        var isEnabled: Bool {
            switch self {
            case let .select(isEnabled):
                return isEnabled

            case let .reorder(isEnabled):
                return isEnabled

            default:
                return true
            }
        }
    }

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

    weak var dataSource: ClipsListNavigationPresenterDataSource?
    weak var navigationBar: ClipsListNavigationBar? {
        didSet {
            self.updateItems()
        }
    }

    // MARK: - Lifecycle

    init(dataSource: ClipsListNavigationPresenterDataSource) {
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
