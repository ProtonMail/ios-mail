//
//  MessageViewModel.swift
//  ProtonMail - Created on 07/03/2019.
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
    

import Foundation


/// ViewModel object of big MessaveViewController screen with a whole thread of messages inside. ViewModel objects of singular messages are nested in `thread` array.
class MessageViewModel: NSObject {
    private(set) var messages: [Message]
    private var observationsHeader: [NSKeyValueObservation] = []
    private var observationsBody: [NSKeyValueObservation] = []
    private var attachmentsObservation: [NSKeyValueObservation] = []
    
    // model - viewModel connections
    @objc private(set) dynamic var thread: [Standalone]
    internal func message(for standalone: Standalone) -> Message? {
        return self.messages.first { $0.messageID == standalone.messageID }
    }
    
    init(conversation messages: [Message]) {
        self.messages = messages
        self.thread = messages.map(Standalone.init)
    }
    
    init(message: Message) {
        self.messages = [message]
        self.thread = [Standalone(message: message)]
    }
    
    internal func locationsForMoreButton() -> [Message.Location] {
        let locations: Array<Message.Location> = [.inbox, .spam, .archive]
        let message = self.messages.first!
        let suitableLocations = locations.filter {
            !message.contains(label: $0) && !(message.contains(label: .sent) && $0 == .inbox)
        }
        return suitableLocations
    }
    
    internal func moveThread(to location: Message.Location) {
        messages.forEach { message in
            guard let label = message.firstValidFolder() else { return }
            sharedMessageDataService.move(message: message, from: label, to: location.rawValue)
        }
    }
    
    internal func reload(message: Message) {
        let standalone = self.thread.first { $0.messageID == message.messageID }!
        standalone.reload(from: message)
    }
    
    internal func reload(message: Message, with bodyPlaceholder: String) {
        let standalone = self.thread.first { $0.messageID == message.messageID }!
        standalone.body = bodyPlaceholder
    }
    
    internal func markThread(read: Bool) {
        self.messages.forEach {
            sharedMessageDataService.mark(message: $0, unRead: !read)
        }
    }
    internal func removeThread() {
        self.messages.forEach { message in
            if message.contains(label: .trash) || message.contains(label: .spam) {
                sharedMessageDataService.delete(message: message, label: Message.Location.trash.rawValue)
            } else {
                if let label = message.firstValidFolder() {
                    sharedMessageDataService.move(message: message, from: label, to: Message.Location.trash.rawValue)
                }
            }
        }
    }
    
    internal func print(_ webView: UIView) -> URL { // TODO: this one will not work for threads
        fatalError()
    }
    
    internal func headersTemporaryUrl() -> URL { // TODO: this one will not work for threads
        guard let message = self.messages.first else {
            assert(false, "No messages in thread")
            return URL(fileURLWithPath: "")
        }
        let headers = message.header
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let filename = formatter.string(from: message.time!) + "-" + message.title.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "-")
        let tempFileUri = FileManager.default.temporaryDirectoryUrl.appendingPathComponent(filename, isDirectory: false).appendingPathExtension("txt")
        try? FileManager.default.removeItem(at: tempFileUri)
        try? headers?.write(to: tempFileUri, atomically: true, encoding: .utf8)
        return tempFileUri
    }
    
    internal func reportPhishing(completion: @escaping (NSError?)->Void) { // TODO: this one will not work for threads
        guard let standalone = self.thread.first else {
            completion(NSError())
            assert(false, "No standalones in thread")
            return
        }

        BugDataService().reportPhishing(messageID: standalone.messageID, messageBody: standalone.body) { error in
            completion(error)
        }
    }
    
    internal func errorWhileReloading(message: Message, error: NSError) {
        switch error.code {
        case NSURLErrorTimedOut:
            self.showErrorBanner(LocalString._general_request_timed_out)
            self.reload(message: message, with: LocalString._general_request_timed_out)

        case NSURLErrorNotConnectedToInternet, NSURLErrorCannotConnectToHost:
            self.showErrorBanner(LocalString._general_no_connectivity_detected)
            self.reload(message: message, with: LocalString._general_no_connectivity_detected)

        case APIErrorCode.API_offline:
            self.showErrorBanner(error.localizedDescription)
            self.reload(message: message, with: error.localizedDescription)

        case APIErrorCode.HTTP503, NSURLErrorBadServerResponse:
            self.showErrorBanner(LocalString._general_api_server_not_reachable)
            self.reload(message: message, with: LocalString._general_api_server_not_reachable)

        case ..<0:
            self.showErrorBanner(LocalString._cant_download_message_body_please_try_again)
            self.reload(message: message, with: LocalString._cant_download_message_body_please_try_again)

        default:
            self.showErrorBanner(LocalString._cant_download_message_body_please_try_again)
            self.reload(message: message, with: LocalString._cant_download_message_body_please_try_again)

        }
        PMLog.D("error: \(error)")
    }
    
    internal func subscribe(toUpdatesOf children: [MessageViewCoordinator.ChildViewModelPack]) {
        self.observationsHeader = []
        self.observationsBody = []
        
        children.enumerated().forEach { index, child in
            let headObservation = child.head.observe(\.contentsHeight) { [weak self] head, _ in
                self?.thread[index].heightOfHeader = head.contentsHeight
            }
            self.observationsHeader.append(headObservation)
            
            let attachmentsObservation = child.attachments.observe(\.contentsHeight) { [weak self] attachments, _ in
                self?.thread[index].heightOfAttachments = attachments.contentsHeight
            }
            self.observationsHeader.append(attachmentsObservation)
            
            let bodyObservation = child.body.observe(\.contentSize) { [weak self] body, _ in
                self?.thread[index].heightOfBody = body.contentSize.height
            }
            self.observationsHeader.append(bodyObservation)
        }
    }
}

extension MessageViewModel {
    private func showErrorBanner(_ title: String) {
        // TODO: use Responder chain to let nearest viewController know we need a banner
    }
}
