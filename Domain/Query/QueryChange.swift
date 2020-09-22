//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum QueryChange<T> {
    case change(T)
    case deleted
    case error(Error)
}
