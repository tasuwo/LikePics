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

        let tabBar = app.tabBars["AppRootTabBarController.tabBar"]

        tabBar
            .buttons["AppRootTabBarController.tabBarItem.top"]
            .tap()
        snapshot("Home")

        tabBar
            .buttons["AppRootTabBarController.tabBarItem.tag"]
            .tap()
        snapshot("Tag")

        tabBar
            .buttons["AppRootTabBarController.tabBarItem.album"]
            .tap()
        snapshot("Album")

        tabBar
            .buttons["AppRootTabBarController.tabBarItem.top"]
            .tap()

        app.collectionViews
            .children(matching: .any)
            .element(boundBy: 0)
            .tap()
        snapshot("Preview")

        app.navigationBars["LikePics.ClipPreviewPageView"]
            .buttons["ClipPreviewPageBarViewController.infoItem"]
            .tap()
        snapshot("Info")
    }
}
