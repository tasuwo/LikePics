//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol Pasteboard {
    func set(_ text: String)
    func get() -> String?
}
