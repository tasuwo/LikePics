//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class ClipPreviewViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ClipPreviewPresenter

    @IBOutlet var collectionView: ClipPreviewCollectionView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: ClipPreviewPresenter) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let layout = self.collectionView?.collectionViewLayout as? ClipPreviewCollectionLayout {
            layout.delegate = self
        }

        self.setupNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.updateNavigationBarAppearance()
    }

    // MARK: - Methods

    private func updateNavigationBarAppearance() {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private func setupNavigationBar() {
        self.navigationItem.title = ""

        self.navigationItem.backBarButtonItem = .init(title: nil,
                                                      style: .plain,
                                                      target: nil,
                                                      action: nil)

        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(self.didTapInfoButton), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = .init(customView: infoButton)
    }

    @objc func didTapInfoButton() {
        print(#function)
    }
}

extension ClipPreviewViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension ClipPreviewViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.presenter.clip.webImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: ClipPreviewCollectionView.cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? ClipPreviewCollectionViewCell else { return dequeuedCell }
        guard self.presenter.clip.webImages.indices.contains(indexPath.row) else { return cell }

        let webImage = self.presenter.clip.webImages[indexPath.row]
        cell.image = webImage.image

        return cell
    }
}

extension ClipPreviewViewController: ClipPreviewCollectionLayoutDelegate {
    // MARK: - ClipPreviewCollectionLayoutDelegate

    func itemWidth(_ collectionView: UICollectionView) -> CGFloat {
        return self.view.bounds.inset(by: self.view.safeAreaInsets).width
    }

    func itemHeight(_ collectionView: UICollectionView) -> CGFloat {
        return self.view.bounds.inset(by: self.view.safeAreaInsets).height
    }
}

extension ClipPreviewViewController: ClipPreviewPresentedViewController {
    // MARK: - ClipPreviewPresentedViewController

    func collectionView(_ animator: ClipPreviewTransitioningAnimator) -> ClipPreviewCollectionView {
        return self.collectionView
    }
}
