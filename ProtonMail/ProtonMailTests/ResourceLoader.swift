//
//  AuthAPITests.swift
//  ProtonMail - Created on 6/17/15.
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

private class ResourceLoader {
    let bundleName : String
    let urls: [URL]
    private var contents: [String: String] = [String: String]()
    
    init?(bundleName: String) {
        self.bundleName = bundleName
        do {
            let dir = Bundle(for: StringConversionTests.self).url(forResource: bundleName, withExtension: "bundle")!
            let contents = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [])
            self.urls = contents
        } catch {
            return nil
        }
    }
    
    func loadContent(by filename: String) -> String? {
        if let content = self.contents[filename] {
            return content
        }
        
        let found = self.urls.filter { (url) -> Bool in
            url.lastPathComponent == filename
        }
        
        guard let url = found.first else {
            return nil
        }
        
        do {
            let content = try String(contentsOf: url).trimmingCharacters(in: .whitespacesAndNewlines)
            self.contents[filename] = content
            return content
        } catch {
            return nil
        }
    }
}

private class ResourceLoaderManager {
    private init() { }
    
    static let shared : ResourceLoaderManager = ResourceLoaderManager()
    private var loaders: [String: ResourceLoader] = [String: ResourceLoader]()
    
    func loader(by bundleName: String) -> ResourceLoader? {
        if let loader = self.loaders[bundleName] {
            return loader
        }
        guard let newLoader = ResourceLoader(bundleName: bundleName) else {
            return nil
        }
        self.loaders[bundleName] = newLoader
        return newLoader
    }
}

protocol Resource {
    var rawValue: String? { get }
}
extension Resource {
    var rawValue: String? {
        get {
            return self.process()
        }
    }
    private func process() -> String? {
        let bundleName = String(describing: type(of: self))
        guard let loader = ResourceLoaderManager.shared.loader(by: bundleName) else {
            return nil
        }
        let fileName = String(describing: self)
        return loader.loadContent(by: fileName)
    }
}
