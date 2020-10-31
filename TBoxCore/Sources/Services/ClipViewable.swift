//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol ClipViewable {
    func existsClip(havingUrl url: URL) -> Bool?
}
