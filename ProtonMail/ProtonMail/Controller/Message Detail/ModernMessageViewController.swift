//
//  ModernMessageViewController.swift
//  ProtonMail - Created on 06/03/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit

class MessageViewController: UITableViewController, ViewModelProtocol, ProtonMailViewControllerProtocol {
    
    // base protocols
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    @IBOutlet weak var menuButton: UIBarButtonItem!
    func configureNavigationBar() {
        ProtonMailViewController.configureNavigationBar(self)
    }
    
    // legacy
    typealias viewModelType = MessageViewModel
    func set(viewModel: MessageViewModel) {
        
    }
    func inactiveViewModel() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBOutlet var backButton: UIBarButtonItem!
    
    fileprivate let kToComposerSegue : String    = "toCompose"
    fileprivate let kSegueMoveToFolders : String = "toMoveToFolderSegue"
    fileprivate let kSegueToApplyLabels : String = "toApplyLabelsSegue"
    fileprivate let kToAddContactSegue : String  = "toAddContact"
    
    var message: Message!
    fileprivate var needShowShowImageView : Bool             = false
    
    // new code
    
    private lazy var bodyController: MessageBodyViewController! = {
        let controller =  self.storyboard?.instantiateViewController(withIdentifier: String(describing: MessageBodyViewController.self)) as? MessageBodyViewController
        controller?.delegate = self
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewController.setup(self, self.menuButton, self.shouldShowSideMenu())
        
        self.addChild(self.bodyController)
        
        self.tableView.rowHeight = UITableView.automaticDimension
    }
}

extension MessageViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        cell.contentView.addSubview(self.bodyController.view)
        cell.contentView.topAnchor.constraint(equalTo: self.bodyController.view.topAnchor).isActive = true
        cell.contentView.bottomAnchor.constraint(equalTo: self.bodyController.view.bottomAnchor).isActive = true
        cell.contentView.leadingAnchor.constraint(equalTo: self.bodyController.view.leadingAnchor).isActive = true
        cell.contentView.trailingAnchor.constraint(equalTo: self.bodyController.view.trailingAnchor).isActive = true
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.bodyController.webView?.scrollView.contentSize.height ?? 10
    }
}

extension MessageViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("commit")
    }
}



class MessageBodyViewController: UIViewController {
    fileprivate var webView: WKWebView!
    internal weak var delegate: WKNavigationDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView = WKWebView(frame: .zero)
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self.delegate
        
        self.view.addSubview(self.webView)
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.webView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
        let html = """
        <html><head><style>dt {clear: left;color: #707070;float: left;max-width: 100px;overflow: hidden;text-align: right;text-overflow: ellipsis;white-space: nowrap;width: 100px;} dd { margin-bottom: 5px;margin-left: 110px;overflow: hidden;text-overflow: ellipsis;white-space: nowrap;}</style></head><body style="font-family: Helvetica; font-size:10pt; word-wrap: break-word; margin: 0px; padding: 10px"><div style="display: block; padding-left: 50px; margin-bottom: 10px;"><img style="float: left; clear: left; margin-left: -50px; border: 0px none; border-radius: 100px; margin-bottom: 10px;" src="https://www.gravatar.com/avatar/5081c8fd2942c85091c7e2102645055c?s=80&amp;d=identicon" alt="Gravatar" height="40" width="40"><span>wip2<br></span></div><dl style="clear: both; float: left; margin-top: 10px; padding: 0px; width: 100%%; box-sizing: border-box;"><dt>Commit:</dt><dd>73fcb8a9c0334a8c533da939d59737cc041dcd83 [73fcb8a9]</dd><dt>Parents:</dt><dd><a href="rev://cf6c86745a6c2d93156e8cedfd75a3324f56338c">cf6c86745a</a></dd><dt>Author:</dt><dd>Anatoly Rosencrantz &lt;rosencrantz@protonmail.com&gt;</dd><dt>Date:</dt><dd>6 March 2019 at 11:36:41 GMT+2</dd><dt>Labels:</dt><dd>refactor/message-view-controller-rewrite</dd></dl></body></html>
        """
        
        self.webView.loadHTMLString(html, baseURL: nil)
    }
}
