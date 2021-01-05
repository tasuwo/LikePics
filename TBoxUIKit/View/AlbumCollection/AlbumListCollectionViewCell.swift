//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import UIKit

public protocol AlbumListCollectionViewCellDelegate: AnyObject {
    func didTapTitleEditButton(_ cell: AlbumListCollectionViewCell)
    func didTapRemover(_ cell: AlbumListCollectionViewCell)
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
            self.updateAppearanceWithAnimation(isEditing: self.isEditing)
        }
    }

    private var isDragging: Bool = false

    public var onReuse: ((String?) -> Void)?

    public weak var delegate: AlbumListCollectionViewCellDelegate?

    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var titleButton: UIButton!
    @IBOutlet var metaLabel: UILabel!
    @IBOutlet var titleEditButton: UIButton!
    @IBOutlet var titleEditButtonContainer: UIView!
    @IBOutlet var titleEditButtonRowStackView: UIStackView!
    @IBOutlet var removerButton: UIButton!
    @IBOutlet var removerContainer: UIView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.onReuse?(self.identifier)
    }

    override public func dragStateDidChange(_ dragState: UICollectionViewCell.DragState) {
        switch dragState {
        case .lifting, .dragging:
            self.isDragging = true
            guard self.isEditing else { return }
            self.updateAppearance(isEditing: false)

        case .none:
            self.isDragging = false
            guard self.isEditing else { return }
            self.updateAppearance(isEditing: true)

        @unknown default:
            break
        }
    }

    // MARK: - IBAction

    @IBAction func didTapTitleEditButton(_ sender: Any) {
        self.delegate?.didTapTitleEditButton(self)
    }

    @IBAction func didTapTitle(_ sender: Any) {
        self.delegate?.didTapTitleEditButton(self)
    }

    @IBAction func didTapRemover(_ sender: Any) {
        self.delegate?.didTapRemover(self)
    }

    // MARK: - Methods

    func setupAppearance() {
        self.thumbnailImageView.layer.cornerRadius = 10
        self.thumbnailImageView.contentMode = .scaleAspectFill

        self.titleButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.titleButton.titleLabel?.lineBreakMode = .byTruncatingTail

        if let imageView = self.removerButton.imageView {
            imageView.backgroundColor = .white
            imageView.layer.cornerRadius = imageView.bounds.width / 2
        }

        self.clipCount = nil
        self.isEditing = false
        self.updateAppearance(isEditing: false)
    }

    func updateAppearance(isEditing: Bool) {
        // HACK: Drop時、StackViewのアニメーション更新がうまくいかないケースがあるため、別途アニメーションせずに
        //       可視性を更新するメソッドを設ける
        DispatchQueue.main.async {
            self.titleButton.isEnabled = isEditing
            self.titleEditButtonContainer.isHidden = !isEditing
            self.removerContainer.isHidden = !isEditing
        }
    }

    func updateAppearanceWithAnimation(isEditing: Bool) {
        guard self.isDragging == false else { return }

        UIView.animate(withDuration: 0.2) {
            self.titleButton.isEnabled = isEditing
            self.titleEditButtonContainer.isHidden = !isEditing
            self.titleEditButtonRowStackView.layoutIfNeeded()
        }

        let displayRemover = isEditing
        if displayRemover {
            self.removerContainer.alpha = 0
            self.removerContainer.isHidden = false
            UIView.animate(withDuration: 0.2) {
                self.removerContainer.alpha = 1
            }
        } else {
            self.removerContainer.alpha = 1
            UIView.animate(withDuration: 0.2) {
                self.removerContainer.alpha = 0
            } completion: { _ in
                self.removerContainer.isHidden = true
                self.removerContainer.alpha = 1
            }
        }
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
