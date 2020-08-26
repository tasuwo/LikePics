//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol SelectedClipContainer: AnyObject {
    var selectedClip: Clip? { get set }
}

typealias ClipsListPreviewableContainer = SelectedClipContainer
