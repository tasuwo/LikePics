//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

protocol ClipsListNavigationPresenterDataSource: AnyObject {
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
        case select
    }

    private var isEditing: Bool = false {
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

    func setEditing(_ editing: Bool, animated: Bool) {
        self.isEditing = editing
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

        if self.isEditing {
            self.navigationBar?.setRightBarButtonItems([.cancel])
            self.navigationBar?.setLeftBarButtonItems([isSelectedAll ? .deselectAll : .selectAll])
        } else {
            self.navigationBar?.setRightBarButtonItems([.select])
            self.navigationBar?.setLeftBarButtonItems([])
        }
    }
}
