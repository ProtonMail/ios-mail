//
//  DKAssetGroupDetailVC.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 15/8/10.
//  Copyright (c) 2015年 ZhangAo. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

private extension UICollectionView {

    func indexPathsForElements(in rect: CGRect, _ hidesCamera: Bool) -> [IndexPath] {
        guard let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect) else {
            assertionFailure("Expect layoutAttributesForElements")
            return []
        }

        if hidesCamera {
            return allLayoutAttributes.map { $0.indexPath }
        } else {
            #if swift(>=4.1)
            return allLayoutAttributes.compactMap { $0.indexPath.item == 0 ? nil : IndexPath(item: $0.indexPath.item - 1, section: $0.indexPath.section) }
            #else
            return allLayoutAttributes.flatMap { $0.indexPath.item == 0 ? nil : IndexPath(item: $0.indexPath.item - 1, section: $0.indexPath.section) }
            #endif
        }
    }

}

////////////////////////////////////////////////////////////

// Show all images in the asset group
open class DKAssetGroupDetailVC: UIViewController,
    UIGestureRecognizerDelegate,
    UICollectionViewDelegate, UICollectionViewDataSource,
    DKImageGroupDataManagerObserver, DKImagePickerControllerObserver,
    DKImagePickerControllerAware {

    public var selectedGroupId: String?
    public weak var imagePickerController: DKImagePickerController?
    internal var collectionView: UICollectionView?
    private var groupListVC: DKAssetGroupListVC?
    private var selectGroupButton: UIButton?
    private var hidesCamera: Bool = false
    private var footerView: UIView?
    private var headerView: UIView?
    private var currentViewSize: CGSize?
    private var registeredCellIdentifiers = Set<String>()
    private var thumbnailSize = CGSize.zero
    private var lastIndexPath: IndexPath?
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        guard let imagePickerController = imagePickerController else {
            assertionFailure("Expect imagePickerController")
            return
        }

        imagePickerController.add(observer: self)

		let layout = imagePickerController.UIDelegate.layoutForImagePickerController(imagePickerController).init()
		let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = imagePickerController.UIDelegate.imagePickerControllerCollectionViewBackgroundColor()
        collectionView.allowsMultipleSelection = true
		collectionView.delegate = self
		collectionView.dataSource = self
		view.addSubview(collectionView)

        self.collectionView = collectionView

		footerView = imagePickerController.UIDelegate.imagePickerControllerFooterView(imagePickerController)
		if let footerView = footerView {
			view.addSubview(footerView)
		}

        headerView = imagePickerController.UIDelegate.imagePickerControllerHeaderView(imagePickerController)
        if let headerView = headerView {
            view.addSubview(headerView)
        }

		hidesCamera = imagePickerController.sourceType == .photo
		checkPhotoPermission()

        if imagePickerController.allowSwipeToSelect && !imagePickerController.singleSelect {
            let swipeOutGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.swiping(gesture:)))
            swipeOutGesture.delegate = self
            collectionView.panGestureRecognizer.require(toFail: swipeOutGesture)
            collectionView.addGestureRecognizer(swipeOutGesture)
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.updateCachedAssets()
    }

    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if let currentViewSize = self.currentViewSize, currentViewSize.equalTo(self.view.bounds.size) {
            return
        } else {
            self.currentViewSize = self.view.bounds.size
        }

        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

	override open func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

        self.configureAccessoryViews()
    }

    open func reload() {
        self.resetCachedAssets()

        guard let imagePickerController = imagePickerController else {
            assertionFailure("Expect imagePickerController")
            return
        }

        imagePickerController.groupDataManager.add(observer: self)
        let groupListVC = DKAssetGroupListVC(imagePickerController: imagePickerController,
                                              defaultAssetGroup: imagePickerController.defaultAssetGroup,
                                              selectedGroupDidChangeBlock: { [unowned self] (groupId) in
                                                self.selectAssetGroup(groupId)
        })
        groupListVC.showsEmptyAlbums = imagePickerController.showsEmptyAlbums
        groupListVC.loadGroups()
        self.groupListVC = groupListVC
        
        self.collectionView?.reloadData()
    }

    func configureAccessoryViews() {
        var footerViewFrame = CGRect.zero
        var headerViewFrame = CGRect.zero
        if let footerView = self.footerView {
            footerViewFrame = CGRect(x: 0,
                                     y: self.view.bounds.height - footerView.bounds.height,
                                     width: self.view.bounds.width,
                                     height: footerView.bounds.height)
            footerView.frame = footerViewFrame
        }
        if let headerView = self.headerView  {
            if #available(iOS 11.0, *) {
                headerViewFrame = CGRect(x: 0,
                                         y: self.view.safeAreaInsets.top,
                                         width: self.view.bounds.width,
                                         height: headerView.bounds.height)
            } else {
                headerViewFrame = CGRect(x: 0,
                                         y: 0,
                                         width: self.view.bounds.width,
                                         height: headerView.bounds.height)
            }
            headerView.frame = headerViewFrame
        }

        if #available(iOS 11.0, *) {
            // Handling Safe Areas for iOS 11
            collectionView?.frame = CGRect(x: 0,
                                           y: self.view.safeAreaInsets.top + headerViewFrame.height,
                                           width: self.view.bounds.width,
                                           height: self.view.bounds.height - footerViewFrame.height - headerViewFrame.height - self.view.safeAreaInsets.top)
        } else {
            collectionView?.frame = CGRect(x: 0,
                                           y: headerViewFrame.height,
                                           width: self.view.bounds.width,
                                           height: self.view.bounds.height - footerViewFrame.height - headerViewFrame.height)
        }
    }

    func checkPhotoPermission() {
		func photoDenied() {
            guard let imagePickerController = imagePickerController else {
                assertionFailure("Expect imagePickerController")
                return
            }
            let permissionColors = imagePickerController.permissionViewColors
            self.view.addSubview(DKPermissionView.permissionView(.photo, withColors: permissionColors))
            self.view.backgroundColor = permissionColors.backgroundColor
			self.collectionView?.isHidden = true
		}

		DKImageDataManager.checkPhotoPermission { granted in
			granted ? self.reload() : photoDenied()
		}
	}

    func selectAssetGroup(_ groupId: String?) {
        if self.selectedGroupId == groupId {
            self.updateTitleView()
            return
        }

        self.selectedGroupId = groupId
        self.updateTitleView()
        self.collectionView?.reloadData()
    }

	open func updateTitleView() {
        guard let selectedGroupId = self.selectedGroupId else { return }
        guard let imagePickerController = imagePickerController else {
            assertionFailure("Expect imagePickerController")
            return
        }
        guard let group = imagePickerController.groupDataManager.fetchGroup(with: selectedGroupId) else {
            assertionFailure("Expect group")
            return
        }
        self.title = group.groupName

        let selectGroupButton = imagePickerController.UIDelegate.imagePickerControllerSelectGroupButton(imagePickerController, selectedGroup: group)
        selectGroupButton.addTarget(self, action: #selector(DKAssetGroupDetailVC.showGroupSelector), for: .touchUpInside)
        self.selectGroupButton = selectGroupButton

        self.navigationItem.titleView = selectGroupButton
	}

    @objc func showGroupSelector() {
        guard let groupListVC = groupListVC else {
            assertionFailure("Expect groupListVC")
            return
        }
        guard let imagePickerController = imagePickerController else {
            assertionFailure("Expect imagePickerController")
            return
        }

        switch imagePickerController.UIDelegate.imagePickerControllerGroupListPresentationStyle() {
        case .popover:
            if let button = self.selectGroupButton {
                DKPopoverViewController.popoverViewController(groupListVC, fromView: button)
            }
        case .presented:
            let navigationController = DKUINavigationController()
            navigationController.setViewControllers([groupListVC], animated: false)
            self.present(navigationController, animated: true, completion: nil)
        }

    }

    func fetchAsset(for index: Int) -> DKAsset? {
        guard let selectedGroupId = self.selectedGroupId else { return nil }

        var assetIndex = index

        if !self.hidesCamera && index == 0 {
            return nil
        }
        assetIndex = (index - (self.hidesCamera ? 0 : 1))

        guard let group = imagePickerController?.groupDataManager.fetchGroup(with: selectedGroupId) else {
            assertionFailure("Expect group")
            return nil
        }
        return imagePickerController?.groupDataManager.fetchAsset(group, index: assetIndex)
    }

    // select an asset at a specific index
    public func selectAsset(atIndex indexPath: IndexPath) {
        self.lastIndexPath = indexPath
        
        guard let imagePickerController = imagePickerController else {
            assertionFailure("Expect imagePickerController")
            return
        }
        guard let cell = collectionView?.cellForItem(at: indexPath) as? DKAssetGroupDetailBaseCell
            , let asset = cell.asset else {
            return
        }

        if !imagePickerController.contains(asset: asset) {
            imagePickerController.select(asset: asset)
            updateTitleView()
        }
    }

    public func deselectAsset(atIndex indexPath: IndexPath) {
        self.lastIndexPath = indexPath
        
        guard let cell = collectionView?.cellForItem(at: indexPath) as? DKAssetGroupDetailBaseCell,
            let asset = cell.asset,
            let imagePickerController = imagePickerController
        else {
                return
        }

        imagePickerController.deselect(asset: asset)
        updateTitleView()
    }

    public func adjustAssetIndex(_ index: Int) -> Int {
        return self.hidesCamera ? index : index + 1
    }
    
    public func scroll(to indexPath: IndexPath, animted: Bool = false) {
        if let cellFrame = self.collectionView?.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame {
            self.collectionView?.scrollRectToVisible(cellFrame, animated: animted)
        }
    }

    public func scrollToLastIndexPath(animated: Bool = false) {
        if let indexPath = self.lastIndexPath {
            self.scroll(to: indexPath, animted: animated)
        }
    }

    public func thumbnailImageView(for indexPath: IndexPath) -> UIImageView? {
        if let cell = self.collectionView?.cellForItem(at: indexPath) as? DKAssetGroupDetailBaseCell {
            return cell.thumbnailImageView
        } else {
            self.collectionView?.reloadItems(at: [indexPath])

            return (self.collectionView?.cellForItem(at: indexPath) as? DKAssetGroupDetailBaseCell)?
                .thumbnailImageView
        }
    }

    func isCameraCell(indexPath: IndexPath) -> Bool {
        return indexPath.row == 0 && !self.hidesCamera
    }

    // MARK: - Swiping

    private var fromIndexPath: IndexPath? = nil
    private var swipingIndexPathes = Set<Int>()
    private var swipingToSelect = true
    private var swipingLastLocation = CGPoint.zero
    private var autoScrollingRate: CGFloat = 1.0
    private var autoScrollingDirection: UISwipeGestureRecognizer.Direction = .down
    private lazy var autoScrollingLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(autoScrolling))
        link.isPaused = true
        link.add(to: RunLoop.main, forMode: .default)
        link.frameInterval = 1
        return link
    }()

    // use the swiping gesture to select the currently swiping cell.
    @objc private func swiping(gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self.collectionView)

        switch gesture.state {
        case .possible:
            break
        case .began:
            if let indexPath = self.collectionView?.indexPathForItem(at: location)
                , let cell = self.collectionView?.cellForItem(at: indexPath) {
                self.fromIndexPath = indexPath
                self.swipingToSelect = !cell.isSelected
            }
        case .changed:
            self.onSwipingChanged(location: location)
            self.startAutoScrollingIfNeeded(location: location)
        case .ended, .cancelled, .failed:
            fallthrough
        @unknown default:
            self.swipingIndexPathes.removeAll()
            self.fromIndexPath = nil
            self.endAutoScrolling()
        }
    }

    private func onSwipingChanged(location: CGPoint) {
        self.swipingLastLocation = location

        if let toIndexPath = self.collectionView?.indexPathForItem(at: location)
            , let fromIndexPath = self.fromIndexPath {
            let begin = min(fromIndexPath.row, toIndexPath.row)
            let end = max(fromIndexPath.row, toIndexPath.row)

            var currentSwipingIndexPathes = Set<Int>()
            for i in begin...end {
                currentSwipingIndexPathes.insert(i)
                self.swipingIndexPathes.remove(i)

                if self.swipingToSelect {
                    self.selectAsset(atIndex: IndexPath(row: i, section: 0))
                } else {
                    self.deselectAsset(atIndex: IndexPath(row: i, section: 0))
                }
            }

            for i in self.swipingIndexPathes {
                if self.swipingToSelect {
                    self.deselectAsset(atIndex: IndexPath(row: i, section: 0))
                } else {
                    self.selectAsset(atIndex: IndexPath(row: i, section: 0))
                }
            }
            self.swipingIndexPathes = currentSwipingIndexPathes
        }
    }

    private func startAutoScrollingIfNeeded(location: CGPoint) {
        guard let collectionView = self.collectionView else {
            assertionFailure("Expect collectionView")
            return
        }

        let minLocationY = collectionView.contentOffset.y
        let maxLocationY = collectionView.bounds.height + collectionView.contentOffset.y

//        debugPrint("minLocationY:\(minLocationY) maxLocationY:\(maxLocationY) current:\(location.y)")

        let locationY = min(max(location.y, minLocationY), maxLocationY)

        self.autoScrollingDirection = locationY - minLocationY > (maxLocationY - minLocationY) / 2 ? .down : .up
        var diff: CGFloat = 0
        switch self.autoScrollingDirection {
        case .down:
            diff = maxLocationY - locationY
        case .up:
            diff = locationY - minLocationY
        default:
            debugPrint("Known direction.")
        }

        let threshold = self.thumbnailSize.height / UIScreen.main.scale
        if diff < threshold {
            self.autoScrollingRate = threshold / max(diff, threshold / 10)
            self.startAutoScrolling()
        } else {
            self.endAutoScrolling()
        }
    }

    private func startAutoScrolling() {
        if self.autoScrollingLink.isPaused {
            self.autoScrollingLink.isPaused = false
        }
    }

    private func endAutoScrolling() {
        if !self.autoScrollingLink.isPaused {
            self.autoScrollingLink.isPaused = true
        }
    }

    @objc private func autoScrolling() {
        guard let collectionView = self.collectionView else {
            assertionFailure("Expect collectionView")
            return
        }

        let offsetY = CGFloat(self.autoScrollingDirection == .down ? self.autoScrollingRate : -self.autoScrollingRate)
        var targetContentOffset = collectionView.contentOffset
        targetContentOffset.y += offsetY

        var safeAreaBottomInset: CGFloat = 0;

        if #available(iOS 11.0, *) {
            safeAreaBottomInset = collectionView.safeAreaInsets.bottom
        }

        targetContentOffset.y = min(max(targetContentOffset.y, collectionView.contentInset.top),
                                    max(collectionView.contentSize.height - (collectionView.bounds.height - safeAreaBottomInset), 0))

        collectionView.contentOffset = targetContentOffset
        
        self.onSwipingChanged(location: CGPoint(x: self.swipingLastLocation.x,
                                                y: self.swipingLastLocation.y + offsetY))
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else { return false }

        let locationPoint = panGesture.location(in: self.collectionView)
        if let indexPath = self.collectionView?.indexPathForItem(at: locationPoint),
            self.isCameraCell(indexPath: indexPath) {
            return false
        }

        let velocityPoint = panGesture.velocity(in: nil)
        let x = abs(velocityPoint.x)
        let y = abs(velocityPoint.y)
        return x > y
    }

    // MARK: - Gallery

    func showGallery(from cell: DKAssetGroupDetailBaseCell) {
        if let groupId = self.selectedGroupId {
            let presentationIndex = cell.tag - 1 - (self.hidesCamera ? 0 : 1)
            imagePickerController?.showGallery(with: presentationIndex,
                                               presentingFromImageView: cell.thumbnailImageView,
                                               groupId: groupId)
        }
    }

    // MARK: - Cells

    func registerCellIfNeeded(cellClass: DKAssetGroupDetailBaseCell.Type) {
        let cellReuseIdentifier = cellClass.cellReuseIdentifier()

        if !self.registeredCellIdentifiers.contains(cellReuseIdentifier) {
            self.collectionView?.register(cellClass, forCellWithReuseIdentifier: cellReuseIdentifier)
            self.registeredCellIdentifiers.insert(cellReuseIdentifier)
        }
    }

    func dequeueReusableCell(for indexPath: IndexPath) -> DKAssetGroupDetailBaseCell {
        guard let imagePickerController = imagePickerController else {
            assertionFailure("Expect imagePickerController")
            return DKAssetGroupDetailBaseCell()
        }
        guard let asset = self.fetchAsset(for: indexPath.row) else {
            assertionFailure("Expect asset")
            return DKAssetGroupDetailBaseCell()
        }

        let cellClass: DKAssetGroupDetailBaseCell.Type
        if asset.type == .video {
            cellClass = imagePickerController.UIDelegate.imagePickerControllerCollectionVideoCell()
        } else {
            cellClass = imagePickerController.UIDelegate.imagePickerControllerCollectionImageCell()
        }
        registerCellIfNeeded(cellClass: cellClass)

        guard let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: cellClass.cellReuseIdentifier(),
                                                                  for: indexPath) as? DKAssetGroupDetailBaseCell else
        {
            assertionFailure("Expect DKAssetGroupDetailBaseCell")
            return DKAssetGroupDetailBaseCell()
        }

        self.setup(assetCell: cell, for: indexPath, with: asset)

        return cell
    }

    func dequeueReusableCameraCell(for indexPath: IndexPath) -> DKAssetGroupDetailBaseCell {
        guard let imagePickerController = self.imagePickerController else {
            assertionFailure("Expect imagePickerController")
            return DKAssetGroupDetailBaseCell()
        }
        let cellClass = imagePickerController.UIDelegate.imagePickerControllerCollectionCameraCell()
        self.registerCellIfNeeded(cellClass: cellClass)
        
        guard let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: cellClass.cellReuseIdentifier(),
                                                                  for: indexPath) as? DKAssetGroupDetailBaseCell else
        {
            assertionFailure("Expect DKAssetGroupDetailBaseCell")
            return DKAssetGroupDetailBaseCell()
        }
        return cell
    }

    func setup(assetCell cell: DKAssetGroupDetailBaseCell, for indexPath: IndexPath, with asset: DKAsset) {
        cell.asset = asset
        let tag = indexPath.row + 1
        cell.tag = tag
        
        if self.thumbnailSize.equalTo(CGSize.zero), let layoutAttributes = self.collectionView?.collectionViewLayout.layoutAttributesForItem(at: indexPath) {
            self.thumbnailSize = layoutAttributes.size.toPixel()
        }
        
        cell.thumbnailImage = nil
        
        asset.fetchImage(with: self.thumbnailSize, options: nil, contentMode: .aspectFill) { [weak cell] (image, info) in
            if let cell = cell, cell.tag == tag, let image = image {
                cell.thumbnailImage = image
            }
        }
        
        cell.longPressBlock = { [weak self, weak cell] in
            guard let strongSelf = self, let strongCell = cell else { return }
            
            strongSelf.showGallery(from: strongCell)
        }
    }

    // MARK: - UICollectionViewDelegate, UICollectionViewDataSource methods

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard let selectedGroupId = self.selectedGroupId else { return self.hidesCamera ? 0 : 1 }

        guard let group = self.imagePickerController?.groupDataManager.fetchGroup(with: selectedGroupId) else {
            assertionFailure("Expect group")
            return 0
        }
        return group.totalCount + (self.hidesCamera ? 0 : 1)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: DKAssetGroupDetailBaseCell
        if self.isCameraCell(indexPath: indexPath) {
            cell = self.dequeueReusableCameraCell(for: indexPath)
        } else {
            cell = self.dequeueReusableCell(for: indexPath)
        }

        if cell.imagePickerController == nil {
            cell.imagePickerController = self.imagePickerController
        }

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let assetCell = cell as? DKAssetGroupDetailBaseCell, let asset = assetCell.asset else { return }

        if let selectedIndex = self.imagePickerController?.index(of: asset) {
            assetCell.isSelected = true
            assetCell.selectedIndex = selectedIndex
            self.collectionView?.selectItem(at: indexPath, animated: false, scrollPosition: [])
        } else {
            assetCell.isSelected = false
            self.collectionView?.deselectItem(at: indexPath, animated: false)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let imagePickerController = self.imagePickerController else {
            assertionFailure("Expect imagePickerController")
            return false
        }
        if let asset = (collectionView.cellForItem(at: indexPath) as? DKAssetGroupDetailBaseCell)?.asset {
            return imagePickerController.canSelect(asset: asset)
        } else {
            return true
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.isCameraCell(indexPath: indexPath) {
            collectionView .deselectItem(at: indexPath, animated: false)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.imagePickerController?.presentCamera()
            }
        } else {
            self.selectAsset(atIndex: indexPath)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.deselectAsset(atIndex: indexPath)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updateCachedAssets()
    }

    // MARK: - Asset Caching

    open func enableCaching() -> Bool {
        return true
    }

    var previousPreheatRect = CGRect.zero

    func resetCachedAssets() {
        guard enableCaching() else { return }

        getImageDataManager().stopCachingForAllAssets()
        self.previousPreheatRect = .zero
    }

    func updateCachedAssets() {
        guard let imagePickerController = self.imagePickerController else {
            assertionFailure("Expect imagePickerController")
            return
        }
        guard let collectionView = self.collectionView else {
            assertionFailure("Expect collectionView")
            return
        }

        guard enableCaching(), let selectedGroupId = self.selectedGroupId else { return }

        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil && self.selectedGroupId != nil else { return }

        // The preheat window is twice the height of the visible rect.
        let preheatRect = view.bounds.insetBy(dx: 0, dy: -0.5 * view.bounds.height)

        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - self.previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }

        guard let group = imagePickerController.groupDataManager.fetchGroup(with: selectedGroupId) else {
            assertionFailure("Expect group")
            return
        }

        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = self.differencesBetweenRects(self.previousPreheatRect, preheatRect)

        let addedAssets = addedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect, self.hidesCamera) }
            .compactMap { indexPath in imagePickerController.groupDataManager.fetchPHAsset(group, index: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect, self.hidesCamera) }
            .compactMap { indexPath in imagePickerController.groupDataManager.fetchPHAsset(group, index: indexPath.item) }

        // Update the assets the PHCachingImageManager is caching.
        getImageDataManager().startCachingAssets(for: addedAssets,
                                                 targetSize: self.thumbnailSize, contentMode: .aspectFill, options: nil)
        getImageDataManager().stopCachingAssets(for: removedAssets,
                                                targetSize: self.thumbnailSize, contentMode: .aspectFill, options: nil)

        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect
    }

    func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }

    // MARK: - DKImagePickerControllerObserver

    func imagePickerControllerDidSelect(assets: [DKAsset]) {
        guard let imagePickerController = self.imagePickerController else {
            assertionFailure("Expect imagePickerController")
            return
        }
        guard let collectionView = self.collectionView else {
            assertionFailure("Expect collectionView")
            return
        }

        if assets.count > 1 {
            collectionView.reloadData()

        } else {
            let asset = assets.first

            for indexPathForVisible in collectionView.indexPathsForVisibleItems {
                if let cell = collectionView.cellForItem(at: indexPathForVisible) as? DKAssetGroupDetailBaseCell {
                    if cell.asset == asset {
                        let selectedIndex = imagePickerController.selectedAssetIdentifiers.count - 1
                        cell.selectedIndex = selectedIndex

                        if !cell.isSelected {
                            collectionView.selectItem(at: indexPathForVisible, animated: true, scrollPosition: [])
                        }

                        break
                    }
                }
            }
        }
    }

    func imagePickerControllerDidDeselect(assets: [DKAsset]) {
        guard let collectionView = self.collectionView else {
            assertionFailure("Expect collectionView")
            return
        }

        for indexPathForVisible in collectionView.indexPathsForVisibleItems {
            if let cell = (collectionView.cellForItem(at: indexPathForVisible) as? DKAssetGroupDetailBaseCell),
                let asset = cell.asset, cell.isSelected {
                if let selectedIndex = self.imagePickerController?.index(of: asset) {
                    cell.selectedIndex = selectedIndex
                } else if cell.isSelected {
                    collectionView.deselectItem(at: indexPathForVisible, animated: true)
                }
            }
        }
    }

	// MARK: - DKImageGroupDataManagerObserver

	func groupDidUpdate(groupId: String) {
		if self.selectedGroupId == groupId {
			self.updateTitleView()
		}
	}

	func group(groupId: String, didRemoveAssets assets: [DKAsset]) {
        guard let imagePickerController = self.imagePickerController else {
            assertionFailure("Expect imagePickerController")
            return
        }

        for removedAsset in assets {
            if imagePickerController.contains(asset: removedAsset) {
                imagePickerController.removeSelection(asset: removedAsset)
            }
        }
	}

    func groupDidUpdateComplete(groupId: String) {
        if self.selectedGroupId == groupId {
            self.resetCachedAssets()
            self.collectionView?.reloadData()
        }
    }
}
