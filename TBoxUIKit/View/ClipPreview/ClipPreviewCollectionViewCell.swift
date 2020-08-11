//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipPreviewCollectionViewCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "ClipPreviewCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public var image: UIImage? {
        get {
            self.imageView.image
        }
        set {
            self.imageView.image = newValue
            if let image = newValue {
                self.imageView.frame = Self.calcCenterizedFrame(ofImage: image, in: self.bounds)
            }
        }
    }

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupScrollView()
        self.setupImageView()
    }

    // MARK: - Methods

    static func calcCenterizedFrame(ofImage image: UIImage, in frame: CGRect) -> CGRect {
        let widthScale = frame.size.width / image.size.width
        let heightScale = frame.size.height / image.size.height
        let scale = min(widthScale, heightScale)

        let imageSize = CGSize(width: image.size.width * scale,
                               height: image.size.height * scale)
        let imageOrigin = CGPoint(x: frame.origin.x + (frame.size.width - imageSize.width) / 2,
                                  y: frame.origin.y + (frame.size.height - imageSize.height) / 2)

        return CGRect(origin: imageOrigin, size: imageSize)
    }

    private func setupScrollView() {
        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 3

        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
    }

    private func setupImageView() {
        self.imageView.contentMode = .scaleAspectFit
    }
}

extension ClipPreviewCollectionViewCell: UIScrollViewDelegate {
    // MARK: - UIScrollViewDelegate

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}
