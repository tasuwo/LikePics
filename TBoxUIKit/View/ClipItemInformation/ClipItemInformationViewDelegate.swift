//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ClipItemInformationViewDelegate: AnyObject {
    func didTapAddTagButton(_ view: ClipItemInformationView)
    func didTapAddToAlbumButton(_ view: ClipItemInformationView)
    func clipItemInformationView(_ view: ClipItemInformationView, didTapDeleteButtonForTag tag: Tag, at placement: UIView)
    func clipItemInformationView(_ view: ClipItemInformationView, shouldOpen url: URL)
    func clipItemInformationView(_ view: ClipItemInformationView, shouldCopy url: URL)
    func clipItemInformationView(_ view: ClipItemInformationView, shouldHide isHidden: Bool)
    func clipItemInformationView(_ view: ClipItemInformationView, startEditingSiteUrl url: URL?)
    func clipItemInformationView(_ view: ClipItemInformationView, didSelectTag tag: Tag)
    func clipItemInformationView(_ view: ClipItemInformationView, didSelectAlbum album: ListingAlbum)
}
