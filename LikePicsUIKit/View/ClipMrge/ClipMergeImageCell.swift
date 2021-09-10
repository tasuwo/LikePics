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

    public var onReuse: ((String?) -> Void)?

    @IBOutlet private var imageView: UIImageView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.onReuse?(self.identifier)
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
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            self.thumbnail = nil
        }
    }

    public func didSuccessToLoad(_ request: ThumbnailRequest, image: UIImage) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            self.thumbnail = image
        }
    }

    public func didFailedToLoad(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            self.thumbnail = nil
        }
    }
}
