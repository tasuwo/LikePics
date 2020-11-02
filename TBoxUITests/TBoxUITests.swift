//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import XCTest

class TBoxUITests: XCTestCase {
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

        app.tabBars["AppRootTabBarController.tabBar"]
            .buttons["AppRootTabBarController.tabBarItem.top"]
            .tap()
        snapshot("Home")

        app.tabBars["AppRootTabBarController.tabBar"]
            .buttons["AppRootTabBarController.tabBarItem.tag"]
            .tap()
        snapshot("Tag")

        app.tabBars["AppRootTabBarController.tabBar"]
            .buttons["AppRootTabBarController.tabBarItem.album"]
            .tap()
        snapshot("Album")

        app.tabBars["AppRootTabBarController.tabBar"]
            .buttons["AppRootTabBarController.tabBarItem.top"]
            .tap()

        app.collectionViews
            .children(matching: .cell)
            .element(boundBy: 0)
            .children(matching: .other).element
            .children(matching: .other).element
            .children(matching: .other)
            .element(boundBy: 0)
            .tap()
        snapshot("Preview")

        app.navigationBars["ClipPreviewPageViewController.navigationBar"]
            .buttons["ClipPreviewPageBarButtonItemsProvider.infoItem"]
            .tap()
        snapshot("Info")
    }
}
