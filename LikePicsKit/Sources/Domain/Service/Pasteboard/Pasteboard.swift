//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public protocol Pasteboard {
    func set(_ text: String)
    func get() -> String?
}
