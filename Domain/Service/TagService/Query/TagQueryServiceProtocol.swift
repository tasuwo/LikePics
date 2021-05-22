//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol TagQueryServiceProtocol {
    func queryTags() -> Result<TagListQuery, ClipStorageError>
}
