//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import UIKit

public class AlbumSelectionCell: UITableViewCell {
    public static var nib: UINib {
        return UINib(nibName: "AlbumSelectionCell", bundle: Bundle(for: Self.self))
    }

    public var identifier: Album.Identity?

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

    public var thumbnailDisplaySize: CGSize {
        thumbnailImageView.bounds.size
    }

    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!

    // MARK: - Methods

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    func setupAppearance() {
        self.thumbnailImageView.layer.cornerRadius = 10
        self.thumbnailImageView.layer.cornerCurve = .continuous
        self.thumbnailImageView.contentMode = .scaleAspectFill
        self.thumbnailImageView.clipsToBounds = true
    }
}

extension AlbumSelectionCell: ThumbnailLoaderObserver {
    // MARK: - ThumbnailLoaderObserver

    public func didStartAsyncLoading(_ loader: ThumbnailLoader, request: ThumbnailRequest) {
        self.thumbnail = nil
    }

    public func didFinishLoad(_ loader: ThumbnailLoader, request: ThumbnailRequest, result: ThumbnailLoadResult) {
        switch result {
        case let .loaded(image):
            self.thumbnail = image

        default:
            self.thumbnail = nil
        }
    }
}
