//
//  DKAssetGroupListVC.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 15/8/8.
//  Copyright (c) 2015年 ZhangAo. All rights reserved.
//

import Photos

let DKImageGroupCellIdentifier = "DKImageGroupCellIdentifier"

class DKAssetGroupCell: UITableViewCell {

    class DKAssetGroupSeparator: UIView {

        override var backgroundColor: UIColor? {
            get {
                return super.backgroundColor
            }
            set {
                if newValue != UIColor.clear {
                    super.backgroundColor = newValue
                }
            }
        }
    }

    fileprivate lazy var thumbnailImageView: UIImageView = {
        let thumbnailImageView = UIImageView()
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true

        return thumbnailImageView
    }()

    lazy var groupNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 13)
        return label
    }()

    lazy var totalCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor.gray
        return label
    }()

    var customSelectedBackgroundView: UIView = {
        let selectedBackgroundView = UIView()

        let selectedFlag = UIImageView(image: DKImagePickerControllerResource.blueTickImage())
        selectedFlag.frame = CGRect(x: selectedBackgroundView.bounds.width - selectedFlag.bounds.width - 20,
                                    y: (selectedBackgroundView.bounds.width - selectedFlag.bounds.width) / 2,
                                    width: selectedFlag.bounds.width, height: selectedFlag.bounds.height)
        selectedFlag.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
        selectedBackgroundView.addSubview(selectedFlag)

        return selectedBackgroundView
    }()

    lazy var customSeparator: DKAssetGroupSeparator = {
        let separator = DKAssetGroupSeparator(frame: CGRect(x: 10, y: self.bounds.height - 1, width: self.bounds.width, height: 0.5))

        separator.backgroundColor = UIColor.lightGray
        separator.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        return separator
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectedBackgroundView = self.customSelectedBackgroundView

        self.contentView.addSubview(self.thumbnailImageView)
        self.contentView.addSubview(self.groupNameLabel)
        self.contentView.addSubview(self.totalCountLabel)

        self.addSubview(self.customSeparator)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let imageViewY = CGFloat(10)
        let imageViewHeight = self.contentView.bounds.height - 2 * imageViewY
        self.thumbnailImageView.frame = CGRect(x: imageViewY,
                                               y: imageViewY,
                                               width: imageViewHeight,
                                               height: imageViewHeight)

        self.groupNameLabel.frame = CGRect(
            x: self.thumbnailImageView.frame.maxX + 10,
            y: self.thumbnailImageView.frame.minY + 5,
            width: 200,
            height: 20)

        self.totalCountLabel.frame = CGRect(
            x: self.groupNameLabel.frame.minX,
            y: self.thumbnailImageView.frame.maxY - 20,
            width: 200,
            height: 20)
    }
}

//////////////////////////////////////////////////////////////////////////////////////////

class DKAssetGroupListVC: UITableViewController, DKImageGroupDataManagerObserver {

    fileprivate var groups: [String]? {
        didSet {
            self.displayGroups = self.filterEmptyGroupIfNeeded()
        }
    }
    
    private var displayGroups: [String]?
    
    var showsEmptyAlbums = true

    fileprivate var selectedGroup: String?

    fileprivate var defaultAssetGroup: PHAssetCollectionSubtype?

    fileprivate var selectedGroupDidChangeBlock:((_ group: String?)->())?

    fileprivate lazy var groupThumbnailRequestOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact

        return options
    }()

    override var preferredContentSize: CGSize {
        get {
            if let groups = self.displayGroups {
                return CGSize(width: UIViewNoIntrinsicMetric,
                              height: CGFloat(groups.count) * self.tableView.rowHeight)
            } else {
                return super.preferredContentSize
            }
        }
        set {
            super.preferredContentSize = newValue
        }
    }
    
    private var groupDataManager: DKImageGroupDataManager!
    
    init(groupDataManager: DKImageGroupDataManager,
         defaultAssetGroup: PHAssetCollectionSubtype?,
         selectedGroupDidChangeBlock: @escaping (_ groupId: String?) -> ()) {
        super.init(style: .plain)
        
        self.groupDataManager = groupDataManager
        self.defaultAssetGroup = defaultAssetGroup
        self.selectedGroupDidChangeBlock = selectedGroupDidChangeBlock
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(DKAssetGroupCell.self, forCellReuseIdentifier: DKImageGroupCellIdentifier)
        self.tableView.rowHeight = 70
        self.tableView.separatorStyle = .none

        self.clearsSelectionOnViewWillAppear = false

        self.groupDataManager.add(observer: self)
    }

    internal func loadGroups() {
        self.groupDataManager.fetchGroups { [weak self] groups, error in
            guard let groups = groups, let strongSelf = self, error == nil else { return }
            
            strongSelf.groups = groups
            strongSelf.selectedGroup = strongSelf.defaultAssetGroupOfAppropriate()
            if let selectedGroup = strongSelf.selectedGroup, let displayGroups = strongSelf.displayGroups, let row = displayGroups.index(of: selectedGroup) {
                strongSelf.tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
                strongSelf.selectedGroupDidChangeBlock?(strongSelf.selectedGroup)
            }
        }
    }

    fileprivate func defaultAssetGroupOfAppropriate() -> String? {
        guard let groups = self.displayGroups else { return nil }
        
        if let defaultAssetGroup = self.defaultAssetGroup {
            for groupId in groups {
                let group = self.groupDataManager.fetchGroupWithGroupId(groupId)
                if defaultAssetGroup == group.originalCollection.assetCollectionSubtype {
                    return groupId
                }
            }
        }
        return groups.first
    }
    
    private func filterEmptyGroupIfNeeded() -> [String]? {
        var displayGroups = self.groups ?? []
        if !self.showsEmptyAlbums {
            if let groups = self.groups {
                for groupId in groups {
                    if self.groupDataManager.fetchGroupWithGroupId(groupId).totalCount > 0 {
                        displayGroups.append(groupId)
                    }
                }
            }
        }
        
        return displayGroups
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.displayGroups?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let groups = self.displayGroups
            , let cell = tableView.dequeueReusableCell(withIdentifier: DKImageGroupCellIdentifier, for: indexPath) as? DKAssetGroupCell else {
                assertionFailure("Expect groups and cell")
                return UITableViewCell()
        }

        let assetGroup = self.groupDataManager.fetchGroupWithGroupId(groups[indexPath.row])
        cell.groupNameLabel.text = assetGroup.groupName

        let tag = indexPath.row + 1
        cell.tag = tag

        if assetGroup.totalCount == 0 {
            cell.thumbnailImageView.image = DKImagePickerControllerResource.emptyAlbumIcon()
        } else {
            self.groupDataManager.fetchGroupThumbnailForGroup(
                assetGroup.groupId,
                size: CGSize(width: tableView.rowHeight, height: tableView.rowHeight).toPixel(),
                options: self.groupThumbnailRequestOptions) { image, info in
                    if cell.tag == tag {
                        cell.thumbnailImageView.image = image
                    }
            }
        }
        cell.totalCountLabel.text = String(assetGroup.totalCount)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DKPopoverViewController.dismissPopoverViewController()
        
        guard let groups = self.displayGroups, groups.count > indexPath.row else {
            assertionFailure("Expect groups with count > \(indexPath.row)")
            return
        }
        
        self.selectedGroup = groups[indexPath.row]
        selectedGroupDidChangeBlock?(self.selectedGroup)
    }
    
    // MARK: - DKImageGroupDataManagerObserver methods
    
    func groupDidUpdate(groupId: String) {
        self.displayGroups = self.filterEmptyGroupIfNeeded()
        
        let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow
        self.tableView.reloadData()
        self.tableView.selectRow(at: indexPathForSelectedRow, animated: false, scrollPosition: .none)
    }
    
    func groupsDidInsert(groupIds: [String]) {
        self.groups! += groupIds
        
        self.willChangeValue(forKey: "preferredContentSize")
        
        let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow
        self.tableView.reloadData()
        self.tableView.selectRow(at: indexPathForSelectedRow, animated: false, scrollPosition: .none)
        
        self.didChangeValue(forKey: "preferredContentSize")
    }
    
    func groupDidRemove(groupId: String) {
        guard let row = self.groups?.index(of: groupId) else { return }
        
        self.willChangeValue(forKey: "preferredContentSize")
        
        self.groups?.remove(at: row)
        
        self.tableView.reloadData()
        if self.selectedGroup == groupId {
            self.selectedGroup = self.displayGroups?.first
            selectedGroupDidChangeBlock?(self.selectedGroup)
            self.tableView.selectRow(at: IndexPath(row: 0, section: 0),
                                     animated: false,
                                     scrollPosition: .none)
        }
        
        self.didChangeValue(forKey: "preferredContentSize")
    }
}
