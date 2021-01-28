//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

/**
 * CollectionViewの初回ロードが重く、Interactiveな画面遷移がカクついてしまうため、
 * ClipInformationViewをViewHierarchy上に事前にロードしておくためのViewController
 */
class PreLoadingClipInformationViewController: UIViewController {
    var currentPageViewControllerProvider: (() -> ClipPreviewViewController?)?

    private let clipId: Clip.Identity
    private let preLoadViewModel: PreLoadingClipInformationViewModelType

    private(set) var preLoadingInformationView = ClipInformationView()
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init(clipId: Clip.Identity,
         preLoadViewModel: PreLoadingClipInformationViewModelType)
    {
        self.clipId = clipId
        self.preLoadViewModel = preLoadViewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    // MARK: PageView Lifecycle

    func pageViewWillDisappear() {
        preLoadViewModel.inputs.stopPreloading()
    }

    func pageViewDidAppear() {
        if !view.subviews.contains(preLoadingInformationView) {
            preLoadingInformationView.alpha = 0
            preLoadingInformationView.dataSource = nil
            self.view.insertSubview(preLoadingInformationView, at: 0)
            NSLayoutConstraint.activate(preLoadingInformationView.constraints(fittingIn: view))
        }

        guard let viewController = currentPageViewControllerProvider?(), !preLoadViewModel.outputs.isPreloading else { return }
        self.preLoadViewModel.inputs.startPreloading(clipId: clipId, itemId: viewController.itemId)
    }

    func pageViewDidLoad() {
        super.viewDidLoad()

        self.setupPreLoadingInformationView()

        self.bind(to: preLoadViewModel)
    }

    func pageViewDidChangedCurrentPage(to viewController: ClipPreviewViewController) {
        DispatchQueue.global().async {
            self.preLoadViewModel.inputs.startPreloading(clipId: self.clipId, itemId: viewController.itemId)
        }
    }

    // MARK: Privates

    private func bind(to dependency: PreLoadingClipInformationViewModelType) {
        dependency.outputs.info
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                self?.preLoadingInformationView.setInfo(info, animated: false)
            }
            .store(in: &self.subscriptions)
    }

    private func setupPreLoadingInformationView() {
        preLoadingInformationView.alpha = 0
        preLoadingInformationView.translatesAutoresizingMaskIntoConstraints = false
        self.view.insertSubview(preLoadingInformationView, at: 0)
        NSLayoutConstraint.activate(preLoadingInformationView.constraints(fittingIn: view))
    }
}
