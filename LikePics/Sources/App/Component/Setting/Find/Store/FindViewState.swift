//
//  Copyright © 2022 Tasuku Tozawa. All rights reserved.
//

import Foundation

struct FindViewState: Equatable, Codable {
    var title: String?
    var currentUrl: URL?
    var canGoBack: Bool
    var canGoForward: Bool
    var isLoading: Bool
    var estimatedProgress: Double

    init() {
        canGoBack = false
        canGoForward = false
        isLoading = false
        estimatedProgress = 0
    }
}

extension FindViewState {
    var isClipEnabled: Bool { !isLoading }
}
