//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol SelectedClipsContainer: AnyObject {
    var selectedClips: [Clip] { get set }
}

protocol ClipsListEditableViewContainer {
    var editableView: ClipsListEditableViewProtocol? { get }
}

typealias ClipsListEditableContainer = ClipsContainer
    & SelectedClipsContainer
    & ClipsListEditableViewContainer
