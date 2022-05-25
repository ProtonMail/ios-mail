//
//  AuthAPITests.swift
//  ProtonMail - Created on 6/17/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit

private class ResourceLoader {
    let bundleName : String
    let urls: [URL]
    private var contents: [String: String] = [String: String]()
    
    init?(bundleName: String) {
        self.bundleName = bundleName
        do {
            let dir = Bundle(for: Self.self).url(forResource: bundleName, withExtension: "bundle")!
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
