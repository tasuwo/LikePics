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
        snapshot("01_Home")

        tabBar
            .buttons["AppRootTabBarController.tabBarItem.search"]
            .tap()
        snapshot("02_Search")

        tabBar
            .buttons["AppRootTabBarController.tabBarItem.tag"]
            .tap()
        snapshot("03_Tag")

        tabBar
            .buttons["AppRootTabBarController.tabBarItem.album"]
            .tap()
        snapshot("04_Album")

        tabBar
            .buttons["AppRootTabBarController.tabBarItem.top"]
            .tap()
        app.collectionViews
            .children(matching: .any)
            .element(boundBy: 0)
            .tap()
        app.navigationBars["LikePics.ClipPreviewPageView"]
            .buttons["ClipPreviewPageBarController.infoItem"]
            .tap()
        snapshot("05_Info")
    }
}
