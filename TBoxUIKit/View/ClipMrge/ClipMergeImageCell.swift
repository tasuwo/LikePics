//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public class ClipMergeImageCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "ClipMergeImageCell", bundle: Bundle(for: Self.self))
    }

    public var identifier: ClipItem.Identity?

    public var thumbnail: UIImage? {
        get {
            self.imageView.image
        }
        set {
            self.imageView.image = newValue
        }
    }

    public var thumbnailDisplaySize: CGSize {
        imageView.bounds.size
    }

    @IBOutlet private var imageView: UIImageView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.imageView.layer.cornerRadius = 10
        self.imageView.layer.cornerCurve = .continuous
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
    }
}

extension ClipMergeImageCell: ThumbnailLoaderObserver {
    // MARK: - ThumbnailLoaderObserver

    public func didStartAsyncLoading(_ loader: ThumbnailLoader, request: ThumbnailRequest) {
        guard self.identifier == request.identifier else { return }
        self.thumbnail = nil
    }

    public func didFinishLoad(_ loader: ThumbnailLoader, request: ThumbnailRequest, result: ThumbnailLoadResult) {
        guard self.identifier == request.identifier else { return }
        switch result {
        case let .loaded(image):
            self.thumbnail = image

        default:
            self.thumbnail = nil
        }
    }
}
