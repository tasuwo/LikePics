//
//  Copyright © 2023 Tasuku Tozawa. All rights reserved.
//

import AppDesktopFeature
import SwiftUI

@main
struct TBoxApp: App {
    var body: some Scene {
        AppScene(try! AppContainer(appBundle: Bundle.main))
    }
}
