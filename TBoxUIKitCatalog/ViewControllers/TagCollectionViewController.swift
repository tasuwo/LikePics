//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class TagCollectionViewController: UIViewController {
    let tags = [
        "hoge",
        "hogehogehogehoge",
        "fugafuga",
        "piyo",
        "popopopo",
        "fugafugafuga",
        "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
        "naruhodo",
        "hoge~~",
        "purupuru",
        "iine!iine!iine!"
    ]

    @IBOutlet var collectionView: TagCollectionView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.allowsSelection = false
        self.collectionView.allowsMultipleSelection = false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        self.collectionView.collectionViewLayout.invalidateLayout()
    }

    @IBAction func didSwitchControl(_ sender: UISegmentedControl) {
        self.collectionView.indexPathsForSelectedItems?.forEach { indexPath in
            self.collectionView.deselectItem(at: indexPath, animated: false)
        }
        switch sender.selectedSegmentIndex {
        case 0:
            self.collectionView.allowsSelection = false
            self.collectionView.allowsMultipleSelection = false
        case 1:
            self.collectionView.allowsSelection = true
            self.collectionView.allowsMultipleSelection = false
        case 2:
            self.collectionView.allowsSelection = false
            self.collectionView.allowsMultipleSelection = true
        default:
            break
        }
    }
}

extension TagCollectionViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected '\(self.tags[indexPath.row])'")
    }
}

extension TagCollectionViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.tags.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionView.cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? TagCollectionViewCell else { return dequeuedCell }

        cell.title = self.tags[indexPath.row]

        return cell
    }
}

extension TagCollectionViewController: UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let preferredSize = TagCollectionViewCell.preferredSize(for: self.tags[indexPath.row])
        return CGSize(width: fmin(preferredSize.width, collectionView.frame.width - 16 * 2), height: preferredSize.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 16, bottom: 16, right: 16)
    }
}
