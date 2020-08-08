//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Kingfisher
import UIKit

class ClipTargetCollectionViewController: UIViewController {
    private let presenter: ClipTargetCollecitonViewPresenter

    @IBOutlet var collectionView: ClipTargetCollectionView!

    // MARK: - Lifecycle

    public init() {
        self.presenter = ClipTargetCollecitonViewPresenter()
        super.init(nibName: "ClipTargetCollectionViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.presenter.view = self
        self.presenter.attachWebView(to: self.view)

        self.setupNavBar()

        guard let item = self.extensionContext?.inputItems.first as? NSExtensionItem else {
            // TODO: Error handling
            print("Error!!")
            return
        }
        self.presenter.findImages(fromItem: item)
    }

    // MARK: - Methods

    private func setupNavBar() {
        self.navigationItem.title = "Select Image!"

        let itemCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
        self.navigationItem.setLeftBarButton(itemCancel, animated: false)

        let itemDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        self.navigationItem.setRightBarButton(itemDone, animated: false)
    }

    @objc private func cancelAction() {
        let error = NSError(domain: "net.tasuwo.TBox", code: 0, userInfo: [NSLocalizedDescriptionKey: "An error description"])
        extensionContext?.cancelRequest(withError: error)
    }

    @objc private func doneAction() {
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
}

extension ClipTargetCollectionViewController: ClipTargetCollectionViewProtocol {
    // MARK: - ClipTargetCollectionViewProtocol

    func show(errorMessage: String) {
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        alert.present(self, animated: true, completion: nil)
    }

    func reload() {
        self.collectionView.reloadData()
    }
}

extension ClipTargetCollectionViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    }
}

extension ClipTargetCollectionViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.presenter.imageUrls.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: type(of: self.collectionView).cellIdentifier, for: indexPath)
        guard self.presenter.imageUrls.indices.contains(indexPath.row) else { return cell }
        let imageUrl = self.presenter.imageUrls[indexPath.row]

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: cell.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: cell.bottomAnchor).isActive = true
        imageView.leftAnchor.constraint(equalTo: cell.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: cell.rightAnchor).isActive = true

        let processor = RoundCornerImageProcessor(cornerRadius: 10)
        imageView.kf.setImage(with: imageUrl, placeholder: nil, options: [.processor(processor)])
        imageView.layer.cornerRadius = 10

        cell.layer.cornerRadius = 10
        cell.backgroundColor = .systemGray6

        let selectedBGView = UIView(frame: cell.frame)
        selectedBGView.backgroundColor = .blue
        cell.selectedBackgroundView = selectedBGView

        return cell
    }
}
