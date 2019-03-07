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
    
    internal func prepareHTMLBody(_ message : Message!) -> String! {
        do {
            let bodyText = try self.message.decryptBodyIfNeeded() ?? LocalString._unable_to_decrypt_message
            return bodyText
        } catch let ex as NSError {
            PMLog.D("purifyEmailBody error : \(ex)")
            return self.message.bodyToHtml()
        }
    }
    
    // new code
    
    private lazy var bodyController: MessageBodyViewController! = {
        let controller =  self.storyboard?.instantiateViewController(withIdentifier: String(describing: MessageBodyViewController.self)) as? MessageBodyViewController
        controller?.delegate = self
        
        controller?.contents = WebContents.init(body: self.prepareHTMLBody(self.message),
                                                remoteContentMode: .lockdown)
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
        self.tableView.reloadData()
    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("commit")
    }
}



class MessageBodyViewController: UIViewController {
    fileprivate var webView: WKWebView!
    internal weak var delegate: WKNavigationDelegate!

    fileprivate var contents: WebContents! {
        didSet {
            guard let webView = self.webView else { return }
            self.loader.load(contents: contents, in: webView)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loader.load(contents: self.contents, in: webView)
    }
    
    private lazy var loader: WebContentsSecureLoader = {
        if #available(iOS 11.0, *) {
            return HTTPRequestSecureLoader()
        } else {
            return HTMLStringSecureLoader()
        }
    }()
    
    deinit {
        self.loader.eject(from: self.webView.configuration)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = false
        preferences.javaScriptCanOpenWindowsAutomatically = false
        
        let config = WKWebViewConfiguration()
        config.preferences = preferences
        self.loader.inject(into: config)
        if #available(iOS 10.0, *) {
            config.dataDetectorTypes = .pm_email
            config.ignoresViewportScaleLimits = true
        }
        
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self.delegate
        
        self.view.addSubview(self.webView)
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.webView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    }
}
