//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

enum Constants {
    static var appGroupIdentifier: String? {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return nil }
        return "group.\(bundleIdentifier)"
    }
}
