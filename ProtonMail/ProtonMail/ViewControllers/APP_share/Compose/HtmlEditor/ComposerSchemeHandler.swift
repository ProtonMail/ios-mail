// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import WebKit

class ComposerSchemeHandler: NSObject, WKURLSchemeHandler {
    private let imageProxy: ImageProxy

    init(imageProxy: ImageProxy) {
        self.imageProxy = imageProxy
        super.init()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url?.absoluteURL else { return }
        let error = NSError(domain: "cache.proton.ch", code: -999)
        imageProxy.fetchRemoteImageIfNeeded(url: url) { result in
            switch result {
            case .success(let remoteImage):
                guard let url = urlSchemeTask.request.url,
                      let response = HTTPURLResponse(
                          url: url,
                          statusCode: 200,
                          httpVersion: "HTTP/2",
                          headerFields: nil
                      ) else {
                    urlSchemeTask.didFailWithError(error)
                    return
                }
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(remoteImage.data)
                urlSchemeTask.didFinish()
            case .failure:
                urlSchemeTask.didFailWithError(error)
            }
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}
