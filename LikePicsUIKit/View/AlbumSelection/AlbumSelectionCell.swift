//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import UIKit

public class AlbumSelectionCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "AlbumSelectionCell", bundle: Bundle(for: Self.self))
    }

    public var identifier: String?

    public var title: String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }

    public var thumbnail: UIImage? {
        get {
            self.thumbnailImageView.image
        }
        set {
            self.thumbnailImageView.image = newValue
        }
    }

    public var clipCount: Int? {
        didSet {
            if let count = self.clipCount {
                self.countLabel.text = L10n.albumListCollectionViewCellCount(count)
                self.countLabel.isHidden = false
            } else {
                self.countLabel.text = nil
                self.countLabel.isHidden = true
            }
        }
    }

    public var onReuse: ((String?) -> Void)?

    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var countLabel: UILabel!

    @IBOutlet var thumbnailWidthConstraint: NSLayoutConstraint!

    // MARK: - Methods

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.onReuse?(self.identifier)
    }

    func setupAppearance() {
        self.thumbnailImageView.layer.cornerRadius = 10
        self.thumbnailImageView.layer.cornerCurve = .continuous
        self.thumbnailImageView.contentMode = .scaleAspectFill
        self.thumbnailImageView.clipsToBounds = true
        self.clipCount = nil
    }
}

extension AlbumSelectionCell: ThumbnailLoadObserver {
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

extension AlbumSelectionCell: ThumbnailPresentable {
    // MARK: - ThumbnailPresentable

    public func calcThumbnailPointSize(originalPixelSize: CGSize?) -> CGSize {
        if let originalSize = originalPixelSize {
            if originalSize.width < originalSize.height {
                return .init(width: thumbnailWidthConstraint.constant,
                             height: thumbnailWidthConstraint.constant * (originalSize.height / originalSize.width))
            } else {
                return .init(width: thumbnailWidthConstraint.constant * (originalSize.width / originalSize.height),
                             height: thumbnailWidthConstraint.constant)
            }
        } else {
            return .init(width: thumbnailWidthConstraint.constant,
                         height: thumbnailWidthConstraint.constant)
        }
    }
}
