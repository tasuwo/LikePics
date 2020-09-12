//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipPreviewPageViewDelegate: AnyObject {
    func clipPreviewPageViewWillBeginZoom(_ view: ClipPreviewPageView)
}

public class ClipPreviewPageView: UIView {
    public var image: UIImage? {
        get {
            self.imageView.image
        }
        set {
            self.imageView.image = newValue

            guard let image = self.imageView.image else { return }
            self.setInitialScale(for: image, on: self.bounds)
            self.updateConstraints(for: image, on: self.bounds)
        }
    }

    public var panGestureRecognizer: UIPanGestureRecognizer {
        self.scrollView.panGestureRecognizer
    }

    public var contentOffset: CGPoint {
        self.scrollView.contentOffset
    }

    public var isMinimumZoomScale: Bool {
        self.scrollView.zoomScale == self.scrollView.minimumZoomScale
    }

    public var isScrollEnabled: Bool {
        get {
            self.scrollView.isScrollEnabled
        }
        set {
            self.scrollView.isScrollEnabled = newValue
        }
    }

    public var imageViewFrame: CGRect {
        self.imageView.frame
    }

    public var zoomGestureRecognizer: UITapGestureRecognizer {
        return self.doubleTapGestureRecognizer
    }

    public weak var delegate: ClipPreviewPageViewDelegate?

    private var doubleTapGestureRecognizer: UITapGestureRecognizer!

    @IBOutlet var baseView: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!

    @IBOutlet var leftInsetConstraint: NSLayoutConstraint!
    @IBOutlet var bottomInsetConstraint: NSLayoutConstraint!
    @IBOutlet var rightInsetConstraint: NSLayoutConstraint!
    @IBOutlet var topInsetConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)

        self.setupFromNib()
        self.setupAppearance()
        self.setupGestureRecognizer()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.setupFromNib()
        self.setupAppearance()
        self.setupGestureRecognizer()
    }

    // MARK: - Methods

    public func shouldRecalculateInitialScale() {
        guard let image = self.imageView.image else { return }
        self.setInitialScale(for: image, on: self.bounds)
        self.updateConstraints(for: image, on: self.bounds)
    }

    private func setupFromNib() {
        Bundle(for: type(of: self)).loadNibNamed("ClipPreviewPageView", owner: self, options: nil)
        self.baseView.frame = self.bounds
        self.addSubview(self.baseView)
        self.sendSubviewToBack(self.baseView)
    }

    private func setupAppearance() {
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.alwaysBounceVertical = false
        self.scrollView.alwaysBounceHorizontal = false
    }

    private func setupGestureRecognizer() {
        self.doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didDoubleTap(_:)))
        self.doubleTapGestureRecognizer.numberOfTapsRequired = 2
        self.addGestureRecognizer(self.doubleTapGestureRecognizer)
    }

    @objc private func didDoubleTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self.imageView)
        guard self.imageView.bounds.contains(point), let image = self.imageView.image else { return }

        let nextScale: CGFloat = {
            if self.scrollView.zoomScale > self.scrollView.minimumZoomScale {
                return self.scrollView.minimumZoomScale
            } else {
                return self.scrollView.maximumZoomScale
            }
        }()

        let currentHorizonalInset = max((self.bounds.width - image.size.width * self.scrollView.zoomScale) / 2, 0)
        let currentVerticalInset = max((self.bounds.height - image.size.height * self.scrollView.zoomScale) / 2, 0)
        let width = self.scrollView.bounds.width / nextScale
        let height = self.scrollView.bounds.height / nextScale
        let nextPoint = CGPoint(x: point.x - (width / 2.0) - currentHorizonalInset,
                                y: point.y - (height / 2.0) - currentVerticalInset)
        let nextRect = CGRect(origin: nextPoint, size: .init(width: width, height: height))

        self.scrollView.zoom(to: nextRect, animated: true)
    }

    func setInitialScale(for image: UIImage, on frame: CGRect) {
        let widthScale = frame.size.width / image.size.width
        let heightScale = frame.size.height / image.size.height
        let scale = min(widthScale, heightScale)

        self.scrollView.minimumZoomScale = scale
        self.scrollView.maximumZoomScale = scale * 3

        self.scrollView.zoomScale = scale
    }

    func updateConstraints(for image: UIImage, on frame: CGRect) {
        let currentScale = self.scrollView.zoomScale

        let horizonalInset = max((frame.width - image.size.width * currentScale) / 2, 0)
        let verticalInset = max((frame.height - image.size.height * currentScale) / 2, 0)

        self.topInsetConstraint.constant = verticalInset
        self.bottomInsetConstraint.constant = verticalInset
        self.leftInsetConstraint.constant = horizonalInset
        self.rightInsetConstraint.constant = horizonalInset

        self.layoutIfNeeded()
        self.scrollView.contentSize = .init(width: self.imageView.frame.width + horizonalInset * 2,
                                            height: self.imageView.frame.height + verticalInset * 2)
    }
}

extension ClipPreviewPageView: UIScrollViewDelegate {
    // MARK: - UIScrollViewDelegate

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let image = self.imageView.image else { return }
        self.updateConstraints(for: image, on: self.bounds)
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.delegate?.clipPreviewPageViewWillBeginZoom(self)
    }
}
