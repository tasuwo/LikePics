//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import UIKit

public class ClipMergeImageCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "ClipMergeImageCell", bundle: Bundle(for: Self.self))
    }

    public var identifier: String?

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

    public var onReuse: () -> Void = {}

    @IBOutlet private var imageView: UIImageView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.onReuse()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.imageView.layer.cornerRadius = 10
        self.imageView.layer.cornerCurve = .continuous
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
    }
}

extension ClipMergeImageCell: ThumbnailLoadObserver {
    // MARK: - ThumbnailLoadObserver

    public func didStartLoading(_ request: ThumbnailRequest) {
        guard self.identifier == request.requestId else { return }
        DispatchQueue.main.async {
            self.thumbnail = nil
        }
    }

    public func didSuccessToLoad(_ request: ThumbnailRequest, image: UIImage) {
        guard self.identifier == request.requestId else { return }
        DispatchQueue.main.async {
            self.thumbnail = image
        }
    }

    public func didFailedToLoad(_ request: ThumbnailRequest) {
        guard self.identifier == request.requestId else { return }
        DispatchQueue.main.async {
            self.thumbnail = nil
        }
    }
}
