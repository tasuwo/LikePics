//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

protocol ClipCollectionToolBarPresenterDataSource: AnyObject {
    func selectedClipsCount(_ presenter: ClipCollectionToolBarPresenter) -> Int
}

protocol ClipCollectionToolBar: AnyObject {
    func showToolBar()
    func hideToolBar()
    func set(_ items: [ClipCollection.ToolBarItem])
}

class ClipCollectionToolBarPresenter {
    private let context: ClipCollection.Context

    private var isEditing: Bool = false {
        didSet {
            self.updateItems()
        }
    }

    var actionTargetCount: Int {
        self.dataSource?.selectedClipsCount(self) ?? 0
    }

    weak var toolBar: ClipCollectionToolBar? {
        didSet {
            self.updateItems()
        }
    }

    weak var dataSource: ClipCollectionToolBarPresenterDataSource?

    // MARK: - Lifecycle

    init(context: ClipCollection.Context, dataSource: ClipCollectionToolBarPresenterDataSource) {
        self.context = context
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
            self.context.isAlbum ? .removeFromAlbum : .delete
        ])
    }
}
