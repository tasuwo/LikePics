//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol ClipItemPreviewViewControllerDelegate: AnyObject {
    func reloadPages(_ viewController: ClipItemPreviewViewController)
}

class ClipItemPreviewViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ClipItemPreviewPresenter

    var clipItem: ClipItem {
        self.presenter.item
    }

    weak var delegate: ClipItemPreviewViewControllerDelegate?

    @IBOutlet var pageView: ClipPreviewPageView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: ClipItemPreviewPresenter) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let data = self.presenter.loadImageData() {
            self.pageView.image = UIImage(data: data)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.pageView.shouldRecalculateInitialScale()
    }

    // MARK: - Methods

    func didTapRemove() {
        self.presenter.didTapRemove()
    }
}

extension ClipItemPreviewViewController: ClipItemPreviewViewProtocol {
    // MARK: - ClipItemPreviewViewProtocol

    func showConfirmationForDelete(options: [ClipItemPreviewPresenter.RemoveTarget], completion: @escaping (ClipItemPreviewPresenter.RemoveTarget?) -> Void) {
        let alert = UIAlertController(title: "", message: "削除しますか？", preferredStyle: .alert)

        let makeOption = { (target: ClipItemPreviewPresenter.RemoveTarget) -> UIAlertAction in
            switch target {
            case .item:
                return .init(title: "表示中の画像を削除", style: .destructive, handler: { _ in completion(.item) })
            case .clip:
                return .init(title: "クリップ全体を削除", style: .destructive, handler: { _ in completion(.clip) })
            }
        }

        options
            .map { makeOption($0) }
            .forEach { alert.addAction($0) }

        alert.addAction(.init(title: "キャンセル", style: .cancel, handler: { _ in
            completion(nil)
        }))

        self.present(alert, animated: true, completion: nil)
    }

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func showSucceededMessage() {
        let alert = UIAlertController(title: "", message: "正常に削除しました", preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
    }

    func reloadPages() {
        self.delegate?.reloadPages(self)
    }

    func closePages() {
        self.dismiss(animated: true, completion: nil)
    }
}
