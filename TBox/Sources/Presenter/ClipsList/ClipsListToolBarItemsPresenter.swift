//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

protocol ClipsListToolBarItemsPresenterDataSouce: AnyObject {
    func selectedClipsCount(_ presenter: ClipsListToolBarItemsPresenter) -> Int
}

protocol ClipsListToolBar: AnyObject {
    func showToolBar()
    func hideToolBar()
    func set(_ items: [ClipsListToolBarItemsPresenter.Item])
}

class ClipsListToolBarItemsPresenter {
    enum Item {
        case spacer
        case add
        case delete
        case removeFromAlbum
        case hide
        case unhide
    }

    enum DisplayTarget {
        case top
        case album
        case searchResult
    }

    private let target: DisplayTarget

    private var isEditing: Bool = false {
        didSet {
            self.updateItems()
        }
    }

    var actionTargetCount: Int {
        self.dataSource?.selectedClipsCount(self) ?? 0
    }

    weak var toolBar: ClipsListToolBar? {
        didSet {
            self.updateItems()
        }
    }

    weak var dataSource: ClipsListToolBarItemsPresenterDataSouce?

    // MARK: - Lifecycle

    init(target: DisplayTarget, dataSource: ClipsListToolBarItemsPresenterDataSouce) {
        self.target = target
        self.dataSource = dataSource
    }

    // MARK: - Methods

    func setEditing(_ editing: Bool, animated: Bool) {
        self.isEditing = editing
    }

    // MARK: Privates

    private func updateItems() {
        if self.isEditing {
            self.toolBar?.showToolBar()
        } else {
            self.toolBar?.hideToolBar()
        }

        self.toolBar?.set([
            .add,
            .spacer,
            .hide,
            .spacer,
            .unhide,
            .spacer,
            self.target == .album ? .removeFromAlbum : .delete
        ])
    }
}
