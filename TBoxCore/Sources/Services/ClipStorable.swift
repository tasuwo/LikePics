//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

public protocol ClipStorable {
    func create(clip: Clip, withData data: [(fileName: String, image: Data)], forced: Bool) -> Result<Void, ClipStorageError>
}
