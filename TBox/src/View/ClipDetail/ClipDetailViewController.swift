//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipDetailViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ClipDetailPresenter

    @IBOutlet var imageView: UIImageView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: ClipDetailPresenter) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupNavigationBar()

        // TODO: Use collection view
        let image = self.presenter.clip.webImages.first!.image
        self.imageView.image = image
        self.imageView.addAspectRatioConstraint(image: image)
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
