//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

protocol ClipPreviewPageNavigationBar: AnyObject {
    func setRightBarItems(_ items: [ClipPreviewPageBarButtonItemsPresenter.Item])
    func setLeftBarItems(_ items: [ClipPreviewPageBarButtonItemsPresenter.Item])
}

protocol ClipPreviewPageToolBar: AnyObject {
    var isLandscape: Bool { get }
    func hide()
    func show()
    func set(_ items: [ClipPreviewPageBarButtonItemsPresenter.Item])
}

protocol ClipPreviewPageBarButtonItemsPresenterDataSource: AnyObject {
    func itemsCount(_ presenter: ClipPreviewPageBarButtonItemsPresenter) -> Int
}

class ClipPreviewPageBarButtonItemsPresenter {
    enum Item {
        case spacer
        case reload
        case deleteOnlyImageOrClip
        case deleteClip
        case openWeb
        case add
        case back
    }

    weak var dataSource: ClipPreviewPageBarButtonItemsPresenterDataSource?

    private weak var navigationBar: ClipPreviewPageNavigationBar?
    private weak var toolBar: ClipPreviewPageToolBar?

    // MARK: - Lifecycle

    init(dataSource: ClipPreviewPageBarButtonItemsPresenterDataSource) {
        self.dataSource = dataSource
    }

    // MARK: - Methods

    func set(navigationBar: ClipPreviewPageNavigationBar, toolBar: ClipPreviewPageToolBar) {
        self.navigationBar = navigationBar
        self.toolBar = toolBar
        self.updateItems()
    }

    func onUpdateClip() {
        self.updateItems()
    }

    func onUpdateOrientation() {
        self.updateItems()
    }

    // MARK: Privates

    private func updateItems() {
        if self.toolBar?.isLandscape == true {
            self.toolBar?.set([])
            self.toolBar?.hide()
            self.navigationBar?.setLeftBarItems([.back])
            self.navigationBar?.setRightBarItems([
                .reload,
                self.dataSource?.itemsCount(self) == 1 ? .deleteClip : .deleteOnlyImageOrClip
            ])
        } else {
            self.toolBar?.set([
                .reload,
                .spacer,
                .openWeb,
                .spacer,
                .add,
                .spacer,
                self.dataSource?.itemsCount(self) == 1 ? .deleteClip : .deleteOnlyImageOrClip
            ])
            self.toolBar?.show()
            self.navigationBar?.setLeftBarItems([.back])
            self.navigationBar?.setRightBarItems([])
        }
    }
}
