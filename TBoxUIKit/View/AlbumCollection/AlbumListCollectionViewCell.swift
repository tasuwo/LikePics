//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import UIKit

public protocol AlbumListCollectionViewCellDelegate: AnyObject {
    func didTapTitleEditButton(_ cell: AlbumListCollectionViewCell)
}

public class AlbumListCollectionViewCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "AlbumListCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public var identifier: String?

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

    public var onReuse: ((String?) -> Void)?

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

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.onReuse?(self.identifier)
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

extension AlbumListCollectionViewCell: ThumbnailLoadObserver {
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
