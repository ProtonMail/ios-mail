//
//  ComposeViewControllerN.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class ComposeViewControllerN: UIViewController {
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    private var composeView : ComposeViewN!
    private var htmlEditor : HtmlEditorViewController!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        composeView = ComposeViewN(nibName: "ComposeViewN", bundle: nil)
        htmlEditor = HtmlEditorViewController()
        
        scrollView.addSubview(composeView.view);
        scrollView.addSubview(htmlEditor.view);
        
        
        
        let f = scrollView.frame

        composeView.view.frame = scrollView.frame
        
        htmlEditor.view.frame = CGRect(x: 0, y: f.height, width: f.width, height: 400)
        
        
//        htmlEditor.view.mas_updateConstraints{ (make) -> Void in
//            make.top.equalTo()(self.composeView.view.mas_bottom)
//            make.left.equalTo()(self.scrollView)
//            make.right.equalTo()(self.scrollView)
//            make.height.equalTo()(800)
//        }
        

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: 2000)
        let frame = scrollView.contentSize;
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
}