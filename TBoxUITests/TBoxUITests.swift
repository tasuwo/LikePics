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
        app/*@START_MENU_TOKEN@*/.tabBars["AppRootTabBarController.tabBar"].buttons["AppRootTabBarController.tabBarItem.top"]/*[[".tabBars[\"Tab Bar\"]",".buttons[\"Home\"]",".buttons[\"AppRootTabBarController.tabBarItem.top\"]",".tabBars[\"AppRootTabBarController.tabBar\"]"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/.tap()
        snapshot("Home")

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
