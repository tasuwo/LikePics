//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol AlbumListCollectionViewCellDelegate: AnyObject {
    func didTapTitleEditButton(_ cell: AlbumListCollectionViewCell)
}

public class AlbumListCollectionViewCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "AlbumListCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public var identifier: Album.Identity?

    public var thumbnail: UIImage? {
        get {
            self.thumbnailImageView.image
        }
        set {
            self.thumbnailImageView.image = newValue
        }
    }

    public var thumbnailSize: CGSize {
        self.thumbnailImageView.bounds.size
    }

    public var title: String? {
        get {
            return self.titleButton.title(for: .normal)
        }
        set {
            self.titleButton.setTitle(newValue, for: .normal)
        }
    }

    public var clipCount: Int? {
        didSet {
            if let count = self.clipCount {
                self.metaLabel.text = L10n.albumListCollectionViewCellCount(count)
                self.metaLabel.isHidden = false
            } else {
                self.metaLabel.text = nil
                self.metaLabel.isHidden = true
            }
        }
    }

    public var isEditing: Bool = false {
        didSet {
            self.updateAppearance()
        }
    }

    public weak var delegate: AlbumListCollectionViewCellDelegate?

    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var titleButton: UIButton!
    @IBOutlet var metaLabel: UILabel!
    @IBOutlet var titleEditButton: UIButton!
    @IBOutlet var titleEditButtonContainer: UIView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    // MARK: - IBAction

    @IBAction func didTapTitleEditButton(_ sender: Any) {
        self.delegate?.didTapTitleEditButton(self)
    }

    @IBAction func didTapTitle(_ sender: Any) {
        self.delegate?.didTapTitleEditButton(self)
    }

    // MARK: - Methods

    func setupAppearance() {
        self.thumbnailImageView.layer.cornerRadius = 10
        self.thumbnailImageView.contentMode = .scaleAspectFill

        self.titleButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.titleButton.titleLabel?.lineBreakMode = .byTruncatingTail

        self.clipCount = nil
        self.isEditing = false
        self.updateAppearance()
    }

    func updateAppearance() {
        self.titleButton.isEnabled = self.isEditing
        self.titleEditButtonContainer.isHidden = !self.isEditing
    }
}

extension AlbumListCollectionViewCell: ThumbnailLoaderObserver {
    // MARK: - ThumbnailLoaderObserver

    public func didStartAsyncLoading(_ loader: ThumbnailLoader, request: ThumbnailRequest) {
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
