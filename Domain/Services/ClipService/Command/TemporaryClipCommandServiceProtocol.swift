//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol TemporaryClipCommandServiceProtocol {
    func create(clip: Clip, withData data: [(fileName: String, image: Data)], forced: Bool) -> Result<Void, ClipStorageError>
}
