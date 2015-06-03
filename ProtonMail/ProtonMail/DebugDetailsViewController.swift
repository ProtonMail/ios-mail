//
//  DebugDetailsViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/3/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
class DebugDetailViewController: UIViewController {
    
    @IBOutlet weak var debugDetail: UITextView!
    
    private var detail : String!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.debugDetail.text = detail
    }
    
    func setDetailText (detail : String)
    {
        self.detail = detail;
    }
    
}
