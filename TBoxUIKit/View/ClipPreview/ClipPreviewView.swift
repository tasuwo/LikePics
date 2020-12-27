//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import UIKit

public protocol ClipPreviewPageViewDelegate: AnyObject {
    func clipPreviewPageViewWillBeginZoom(_ view: ClipPreviewView)
}

public class ClipPreviewView: UIView {
    public typealias Source = (image: UIImage, imageSize: CGSize)

    public var source: Source? {
        didSet {
            guard let source = self.source else { return }
            self.imageView.image = source.image
        }
    }

    public var image: UIImage? {
        self.imageView.image
    }

    public var panGestureRecognizer: UIPanGestureRecognizer {
        self.scrollView.panGestureRecognizer
    }

    public var contentOffset: AnyPublisher<CGPoint, Never> {
        KeyValueObservingPublisher(object: scrollView, keyPath: \.contentOffset, options: .new)
            .eraseToAnyPublisher()
    }

    private let _isMinimumZoomScale: CurrentValueSubject<Bool, Never> = .init(true)
    public var isMinimumZoomScale: AnyPublisher<Bool, Never> {
        self._isMinimumZoomScale.eraseToAnyPublisher()
    }

    public var isScrollEnabled: Bool {
        get {
            self.scrollView.isScrollEnabled
        }
        set {
            self.scrollView.isScrollEnabled = newValue
        }
    }

    public var initialImageFrame: CGRect {
        guard let source = self.source else { return .zero }
        let scale = min(1, Self.calcScaleScaleToFit(forSize: source.imageSize, fittingIn: self.bounds.size))
        let initialImageSize = CGSize(width: source.imageSize.width * scale,
                                      height: source.imageSize.height * scale)
        return CGRect(origin: CGPoint(x: (self.bounds.width - initialImageSize.width) / 2,
                                      y: (self.bounds.height - initialImageSize.height) / 2),
                      size: initialImageSize)
    }

    public var zoomGestureRecognizer: UITapGestureRecognizer {
        return self.doubleTapGestureRecognizer
    }

    public weak var delegate: ClipPreviewPageViewDelegate?

    private var doubleTapGestureRecognizer: UITapGestureRecognizer!

    private lazy var logger: TBoxLoggable = RootLogger.shared

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

    static func calcScaleScaleToFit(forSize source: CGSize, fittingIn destination: CGSize) -> CGFloat {
        let widthScale = destination.width / source.width
        let heightScale = destination.height / source.height
        return min(widthScale, heightScale)
    }

    /**
     * SafeAreaのない端末にて、
     *
     * 1. 初期状態からダブルタップ
     * 2. NavigationBarが非表示になる
     * 3. `ClipPreviewViewController#viewDidLayoutSubviews` が実行される
     * 4. このメソッドが実行され、スケールが初期位置に戻される
     *
     * といった事象が発生した。そのため、レイアウト調整は初期状態に限る
     */
    public func shouldRecalculateInitialScale() {
        guard self.scrollView.zoomScale == self.scrollView.minimumZoomScale else { return }
        guard let source = self.source else { return }
        self.setupScale(forImageSize: source.imageSize, on: self.bounds.size)
        self.updateConstraints(forImageSize: source.imageSize, on: self.bounds)
    }

    private func setupFromNib() {
        Bundle(for: type(of: self)).loadNibNamed("ClipPreviewView", owner: self, options: nil)
        self.baseView.frame = self.bounds
        self.addSubview(self.baseView)
        self.sendSubviewToBack(self.baseView)
    }

    private func setupAppearance() {
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.alwaysBounceVertical = false
        self.scrollView.alwaysBounceHorizontal = false
        self.scrollView.contentInsetAdjustmentBehavior = .never
    }

    private func setupGestureRecognizer() {
        self.doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didDoubleTap(_:)))
        self.doubleTapGestureRecognizer.numberOfTapsRequired = 2
        self.addGestureRecognizer(self.doubleTapGestureRecognizer)
    }

    @objc
    private func didDoubleTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self.imageView)
        guard self.imageView.bounds.contains(point), let image = self.imageView.image else { return }

        let nextScale: CGFloat = {
            if self.scrollView.zoomScale > self.scrollView.minimumZoomScale {
                return self.scrollView.minimumZoomScale
            } else {
                return self.scrollView.maximumZoomScale
            }
        }()

        let currentHorizontalInset = max((self.bounds.width - image.size.width * self.scrollView.zoomScale) / 2, 0)
        let currentVerticalInset = max((self.bounds.height - image.size.height * self.scrollView.zoomScale) / 2, 0)
        let width = self.scrollView.bounds.width / nextScale
        let height = self.scrollView.bounds.height / nextScale
        let nextPoint = CGPoint(x: point.x - (width / 2.0) - currentHorizontalInset,
                                y: point.y - (height / 2.0) - currentVerticalInset)
        let nextRect = CGRect(origin: nextPoint, size: .init(width: width, height: height))

        self.scrollView.zoom(to: nextRect, animated: true)
    }

    private func setupScale(forImageSize imageSize: CGSize, on size: CGSize) {
        let scaleToFit = Self.calcScaleScaleToFit(forSize: imageSize, fittingIn: size)

        self.scrollView.minimumZoomScale = min(1, scaleToFit)
        self.scrollView.maximumZoomScale = max(1, scaleToFit)

        self.scrollView.zoomScale = self.scrollView.minimumZoomScale
    }

    private func updateConstraints(forImageSize imageSize: CGSize, on frame: CGRect) {
        let currentScale = self.scrollView.zoomScale

        let horizontalInset = max((frame.width - imageSize.width * currentScale) / 2, 0)
        let verticalInset = max((frame.height - imageSize.height * currentScale) / 2, 0)

        self.topInsetConstraint.constant = verticalInset
        self.bottomInsetConstraint.constant = verticalInset
        self.leftInsetConstraint.constant = horizontalInset
        self.rightInsetConstraint.constant = horizontalInset

        self.layoutIfNeeded()
        self.scrollView.contentSize = .init(width: self.imageView.frame.width + horizontalInset * 2,
                                            height: self.imageView.frame.height + verticalInset * 2)
    }
}

extension ClipPreviewView: UIScrollViewDelegate {
    // MARK: - UIScrollViewDelegate

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let source = self.source else { return }
        self.updateConstraints(forImageSize: source.imageSize, on: self.bounds)
        self._isMinimumZoomScale.send(scrollView.zoomScale == scrollView.minimumZoomScale)
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.delegate?.clipPreviewPageViewWillBeginZoom(self)
    }
}
