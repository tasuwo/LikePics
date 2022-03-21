//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import XCTest

class LikePicsUITests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()

        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func testExample() throws {
        let app = XCUIApplication()
        let device = XCUIDevice.shared

        if UIDevice.current.userInterfaceIdiom == .phone {
            device.orientation = .portrait

            let tabBar = app.tabBars["SceneRootTabBarController.tabBar"]

            tabBar
                .buttons["SceneRoot.TabBarItem.top"]
                .tap()
            snapshot("01_Home")

            tabBar
                .buttons["SceneRoot.TabBarItem.tag"]
                .tap()
            snapshot("03_Tag")

            tabBar
                .buttons["SceneRoot.TabBarItem.album"]
                .tap()
            snapshot("04_Album")

            tabBar
                .buttons["SceneRoot.TabBarItem.top"]
                .tap()
            app.collectionViews["ClipCollectionViewController.collectionView"]
                .children(matching: .cell)
                .element(boundBy: 4)
                .tap()
            app.navigationBars["AppFeature.ClipPreviewPageView"]
                .buttons["ClipPreviewPageBarController.infoItem"]
                .tap()
            snapshot("02_Info")
        } else {
            device.orientation = .portrait

            let sideBar = app.collectionViews["SceneRootSideBarController.collectionView"]

            app.navigationBars
                .buttons
                .element(boundBy: 0)
                .tap()
            sideBar
                .children(matching: .cell)
                .element(boundBy: 0)
                .tap()
            sideBar
                .coordinate(withNormalizedOffset: .init(dx: 1, dy: 0.5))
                .withOffset(.init(dx: 10, dy: 0))
                .tap()
            snapshot("01_Home")

            app.navigationBars
                .buttons
                .element(boundBy: 0)
                .tap()
            sideBar
                .children(matching: .cell)
                .element(boundBy: 2)
                .tap()
            sideBar
                .coordinate(withNormalizedOffset: .init(dx: 1, dy: 0.5))
                .withOffset(.init(dx: 10, dy: 0))
                .tap()
            snapshot("03_Tag")

            app.navigationBars
                .buttons
                .element(boundBy: 0)
                .tap()
            sideBar
                .children(matching: .cell)
                .element(boundBy: 3)
                .tap()
            sideBar
                .coordinate(withNormalizedOffset: .init(dx: 1, dy: 0.5))
                .withOffset(.init(dx: 10, dy: 0))
                .tap()
            snapshot("04_Album")

            app.navigationBars
                .buttons
                .element(boundBy: 0)
                .tap()
            sideBar
                .children(matching: .cell)
                .element(boundBy: 0)
                .tap()
            sideBar
                .coordinate(withNormalizedOffset: .init(dx: 1, dy: 0.5))
                .withOffset(.init(dx: 10, dy: 0))
                .tap()
            app.collectionViews["ClipCollectionViewController.collectionView"]
                .children(matching: .cell)
                .element(boundBy: 0)
                .tap()
            app.navigationBars["AppFeature.ClipPreviewPageView"]
                .buttons["ClipPreviewPageBarController.infoItem"]
                .tap()
            snapshot("02_Info")
        }
    }
}
