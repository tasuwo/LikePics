//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

class Router: ObservableObject {
    @Published var path: NavigationPath = .init()
}

private struct RouterBuilderKey: EnvironmentKey {
    static let defaultValue: Router = .init()
}

extension EnvironmentValues {
    var router: Router {
        get { self[RouterBuilderKey.self] }
        set { self[RouterBuilderKey.self] = newValue }
    }
}
