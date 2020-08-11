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
