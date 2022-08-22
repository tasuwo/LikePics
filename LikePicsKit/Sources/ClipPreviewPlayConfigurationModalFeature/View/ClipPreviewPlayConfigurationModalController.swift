//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import Environment
import LikePicsUIKit
import UIKit

public class ClipPreviewPlayConfigurationModalController: UIViewController {
    static let minInterval = 3
    static let maxInterval = 60

    typealias Layout = ClipPreviewPlayConfigurationModalLayout

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!

    // MARK: Component

    private let intervalEditAlert: TextEditAlertController

    // MARK: Service

    private let modalNotificationCenter: ModalNotificationCenter
    private let storage: ClipPreviewPlayConfigurationStorageProtocol

    // MARK: Store

    public let id: UUID
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    public init(id: UUID,
                modalNotificationCenter: ModalNotificationCenter,
                storage: ClipPreviewPlayConfigurationStorageProtocol)
    {
        self.id = id
        self.modalNotificationCenter = modalNotificationCenter
        self.storage = storage
        self.intervalEditAlert = .init(state: .init(title: L10n.Root.IntervalAlert.title,
                                                    message: L10n.Root.IntervalAlert.message(Self.minInterval, Self.maxInterval),
                                                    placeholder: "",
                                                    keyboardType: .asciiCapableNumberPad))
        super.init(nibName: nil, bundle: nil)

        intervalEditAlert.textEditAlertDelegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureViewHierarchy()
        configureDataSource()

        bind()
    }
}

// MARK: - Bind

extension ClipPreviewPlayConfigurationModalController {
    private func bind() {
        storage
            .animation
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self, let dataSource = self.dataSource else { return }
                var snapshot = dataSource.snapshot()
                if #available(iOS 15.0, *) {
                    snapshot.reconfigureItems([.animation])
                } else {
                    snapshot.reloadItems([.animation])
                }
                dataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &subscriptions)

        storage
            .order
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self, let dataSource = self.dataSource else { return }
                var snapshot = dataSource.snapshot()
                if #available(iOS 15.0, *) {
                    snapshot.reconfigureItems([.order])
                } else {
                    snapshot.reloadItems([.order])
                }
                dataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &subscriptions)

        storage
            .range
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self, let dataSource = self.dataSource else { return }
                var snapshot = dataSource.snapshot()
                if #available(iOS 15.0, *) {
                    snapshot.reconfigureItems([.range])
                } else {
                    snapshot.reloadItems([.range])
                }
                dataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &subscriptions)

        storage
            .interval
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self, let dataSource = self.dataSource else { return }
                var snapshot = dataSource.snapshot()
                if #available(iOS 15.0, *) {
                    snapshot.reconfigureItems([.interval])
                } else {
                    snapshot.reloadItems([.interval])
                }
                dataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &subscriptions)

        storage
            .loopEnabled
            .removeDuplicates()
            .sink { [weak self] loopEnabled in
                guard let self = self, let dataSource = self.dataSource else { return }
                if let indexPath = dataSource.indexPath(for: .loop),
                   let cell = self.collectionView.cellForItem(at: indexPath) as? UICollectionViewListCell,
                   let `switch` = cell.accessories.pickSwitch(),
                   `switch`.isOn != loopEnabled
                {
                    `switch`.setOnSmoothly(loopEnabled)
                }
            }
            .store(in: &subscriptions)
    }
}

// MARK: - Configuration

extension ClipPreviewPlayConfigurationModalController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))
    }

    private func configureNavigationBar() {
        navigationItem.title = L10n.Root.title

        let addItem = UIBarButtonItem(systemItem: .done, primaryAction: .init(handler: { [weak self] _ in
            guard let self = self else { return }
            self.modalNotificationCenter.post(id: self.id, name: .clipPreviewPlayConfigurationModalDidDismiss, userInfo: nil)
            self.dismissAll(completion: nil)
        }), menu: nil)

        navigationItem.rightBarButtonItem = addItem
    }

    private func configureDataSource() {
        dataSource = Layout.configureDataSource(collectionView: collectionView, storage: storage) { [weak self] in
            self?.storage.set(loopEnabled: $0)
        } onIntervalEdit: { [weak self] in
            guard let self = self else { return }
            self.intervalEditAlert.present(with: "\(self.storage.fetchInterval())",
                                           validator: { text in
                                               guard let txt = text, let interval = Int(txt) else { return false }
                                               return interval >= Self.minInterval && interval <= Self.maxInterval
                                           },
                                           on: self)
        }

        var snapshot = Layout.Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(Layout.Item.allCases)
        dataSource.apply(snapshot)
    }
}

extension ClipPreviewPlayConfigurationModalController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .animation:
            self.show(ClipPreviewAnimationSelectionViewController(storage: storage), sender: nil)

        case .order:
            self.show(ClipPreviewOrderSelectionViewController(storage: storage), sender: nil)

        case .range:
            self.show(ClipPreviewRangeSelectionViewController(storage: storage), sender: nil)

        default:
            break
        }
    }
}

extension ClipPreviewPlayConfigurationModalController: TextEditAlertDelegate {
    // MARK: - TextEditAlertDelegate

    public func textEditAlert(_ id: UUID, didTapSaveWithText text: String) {
        guard let interval = Int(text) else { return }
        storage.set(interval: interval)
    }

    public func textEditAlertDidCancel(_ id: UUID) {
        // NOP
    }
}

extension ClipPreviewPlayConfigurationModalController: UIAdaptivePresentationControllerDelegate {
    // MARK: - UIAdaptivePresentationControllerDelegate

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        modalNotificationCenter.post(id: id, name: .clipPreviewPlayConfigurationModalDidDismiss)
    }
}

extension ClipPreviewPlayConfigurationModalController: ModalController {}

private extension Array where Element == UICellAccessory {
    func pickSwitch() -> UISwitch? {
        for accessory in self {
            guard case let .customView(view) = accessory.accessoryType,
                  let `switch` = view as? UISwitch else { continue }
            return `switch`
        }
        return nil
    }
}
