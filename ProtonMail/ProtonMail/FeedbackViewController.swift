//
//  FeedbackViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/11/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation
import Social


protocol FeedbackViewControllerDelegate {
    func dismissed();
}

class FeedbackViewController : ProtonMailViewController, UITableViewDelegate, UITableViewDataSource {
    
    fileprivate let sectionSource : [FeedbackSection] = [.header, .reviews, .guid]
    fileprivate let dataSource : [FeedbackSection : [FeedbackItem]] = [.header : [.header], .reviews : [.rate, .tweet, .facebook], .guid : [.guide, .contact]]
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension;
        tableView.estimatedRowHeight = 36.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
     /**
    tableview
    
    - parameter tableView:
    
    - returns:
    */
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let items = dataSource[sectionSource[section]]
        return items?.count ?? 0
    }
    
    @objc func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let key = sectionSource[section]
        if key.hasTitle {
            let cell: FeedbackHeadCell = tableView.dequeueReusableCell(withIdentifier: "feedback_table_section_header_cell") as! FeedbackHeadCell
            cell.configCell(key.title)
            return cell;
        } else {
            return nil
        }
    }
    
    @objc func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    @objc func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    @objc func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let key = sectionSource[section]
        if key.hasTitle {
            return 46
        } else {
            return 0.01
        }
    }

    @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = sectionSource[indexPath.section]
        let items : [FeedbackItem]? = dataSource[key]
        if key == .header {

        } else {
            if let item = items?[indexPath.row] {
                if item == .rate {
                    openRating()
                } else if item == .tweet {
                    shareMore()
                } else if item == .facebook {
                    
                    shareFacebook()
                }
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        let _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let key = sectionSource[indexPath.section]
        let items : [FeedbackItem]? = dataSource[key]
        if key == .header {
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "feedback_table_top_cell", for: indexPath)
            cell.selectionStyle = .none
            return cell
        } else {
            let cell: FeedbackTableViewCell = tableView.dequeueReusableCell(withIdentifier: "feedback_table_detail_cell", for: indexPath) as! FeedbackTableViewCell
            if let item = items?[indexPath.row] {
                cell.configCell(item)
            }
            return cell
        }
    }
//    override func cellfor
    
    func openRating () {
        let url :URL = URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=979659905")!
        UIApplication.shared.openURL(url)
    }
    
    func shareFacebook () {
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook) {
            let facebookComposeVC = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
            let url = "https://protonmail.com";
            facebookComposeVC?.setInitialText("ProtonMail post .... \(url)")
            
            self.present(facebookComposeVC!, animated: true, completion: nil)
        }
        
    }
    
    func shareMore () {
        
//        let bounds = UIScreen.mainScreen().bounds
//        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
//        self.view.drawViewHierarchyInRect(bounds, afterScreenUpdates: false)
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        let URL = NSURL(string: "http://protonmail.com/")!
//        let text = "ProtonMail post default... #ProtonMail \(URL)"
//        
//        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
//        
//        let iTems = self.extensionContext?.inputItems
//        let url = NSURL(string: "https://protonmail.com")!
////        let image = UIImage(named:"trash")!
////        let text : String = "ProtonMail post default";
////        let activityViewController = UIActivityViewController(activityItems: [image, text, url], applicationActivities: nil)
//        
//        activityViewController.excludedActivityTypes = []
//        
//        self.presentViewController(activityViewController, animated: true, completion: nil)
//        
//        
//        
//        
//        
////        NSDictionary *item = @{ AppExtensionVersionNumberKey: VERSION_NUMBER, AppExtensionURLStringKey: URLString };
////        
////        UIActivityViewController *activityViewController = [self activityViewControllerForItem:item viewController:viewController sender:sender typeIdentifier:kUTTypeAppExtensionFindLoginAction];
////        activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
////            if (returnedItems.count == 0) {
////                NSError *error = nil;
////                if (activityError) {
////                    NSLog(@"Failed to findLoginForURLString: %@", activityError);
////                    error = [OnePasswordExtension failedToContactExtensionErrorWithActivityError:activityError];
////                }
////                else {
////                    error = [OnePasswordExtension extensionCancelledByUserError];
////                }
////                
////                if (completion) {
////                    completion(nil, error);
////                }
////                
////                return;
////            }
////            
////            [self processExtensionItem:returnedItems.firstObject completion:^(NSDictionary *itemDictionary, NSError *error) {
////                if (completion) {
////                completion(itemDictionary, error);
////                }
////                }];
////        };
////        
////        [viewController presentViewController:activityViewController animated:YES completion:nil];

    }
    
    @objc func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.zeroMargin()
    }
}
