//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import SwiftUI

class Router: ObservableObject {
    @Published var path: NavigationPath = .init()
}
