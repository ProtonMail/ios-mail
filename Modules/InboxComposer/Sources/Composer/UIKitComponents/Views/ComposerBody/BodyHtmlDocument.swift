// Copyright (c) 2024 Proton Technologies AG
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

import Foundation
import InboxCoreUI
import InboxDesignSystem
import SwiftUICore

struct BodyHtmlDocument {
    private typealias ColorBundle = (background: String, text: String, brand: String)

    private static func colorBundle(for colorScheme: ColorScheme) -> ColorBundle {
        var env = EnvironmentValues()
        env.colorScheme = colorScheme
        let backgroundColor = DS.Color.Background.norm.hexString(in: env)
        let textColor = DS.Color.Text.norm.hexString(in: env)
        let brandColor = DS.Color.Brand.norm.hexString(in: env)
        return (background: backgroundColor, text: textColor, brand: brandColor)
    }

    private let css: String = {
        let fileURL = Bundle.module.url(forResource: "BodyHtmlStyling", withExtension: "css")!
        let content = try! String(contentsOf: fileURL)

        let lightBundle = colorBundle(for: .light)
        let darkBundle = colorBundle(for: .dark)

        return content
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "{{proton-background-color}}", with: lightBundle.background)
            .replacingOccurrences(of: "{{proton-text-color}}", with: lightBundle.text)
            .replacingOccurrences(of: "{{proton-brand-color}}", with: lightBundle.brand)
            .replacingOccurrences(of: "{{proton-background-color-dark}}", with: darkBundle.background)
            .replacingOccurrences(of: "{{proton-text-color-dark}}", with: darkBundle.text)
            .replacingOccurrences(of: "{{proton-brand-color-dark}}", with: darkBundle.brand)

    }()

    func html(withTextEditorContent content: String) -> String {
        htmlTemplate
            .replacingOccurrences(of: HtmlPlaceholder.body, with: content)
            .replacingOccurrences(of: HtmlPlaceholder.css, with: css)
            .replacingOccurrences(of: HtmlPlaceholder.script, with: script)
    }
}

extension BodyHtmlDocument {

    enum Event {
        case onContentHeightChange
        case onEditorFocus
        case onEditorChange
    }

    enum EventAttributeKey {
        static let height = "height"
    }

    enum JSFunction: String {
        case setFocus = "html_editor.setFocus"
        case getHtmlContent = "html_editor.getHtmlContent"

        var callFunction: String {
            "\(self.rawValue)();"
        }
    }

    enum JSEventHandler: String, CaseIterable {
        case bodyResize
        case focus
        case editorChanged

        var event: Event {
            switch self {
            case .bodyResize: .onContentHeightChange
            case .focus: .onEditorFocus
            case .editorChanged: .onEditorChange
            }
        }
    }
}

// MARK: Private

private extension BodyHtmlDocument {

    enum HtmlPlaceholder {
        static let body = "<!--INSERT_BODY-->"
        static let css = "<!--CSS-->"
        static let script = "<!--JS_SCRIPT-->"
    }

    enum ID {
        static let editor = "editor"
    }
}

// MARK: HTML

private extension BodyHtmlDocument {

    var htmlTemplate: String {
    """
    <!DOCTYPE html>
    <html lang="en">
        <head>
            <title>Proton HTML Editor</title>
            <meta id="myViewport" name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, shrink-to-fit=yes">
            <meta id="myCSP" http-equiv="Content-Security-Policy" content="script-src 'unsafe-inline' 'unsafe-eval'">
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
            <style>
                \(HtmlPlaceholder.css)
            </style>
        </head>
        <body>
            <div id="editor_header">
            </div>
            <div role="textbox" aria-multiline="true" id="\(ID.editor)" contentEditable="true" placeholder="" class="placeholder">
                \(HtmlPlaceholder.body)
            </div>
            <div id="editor_footer">
            </div>
            <script>
                \(HtmlPlaceholder.script)
            </script>
        </body>
    </html>
    """
    }
}

// MARK: Scripts

private extension BodyHtmlDocument {

    var script: String {
    """
    "use strict";
    var html_editor = {};

    // --------------------
    // Event listeners
    // --------------------

    document.getElementById('\(ID.editor)').addEventListener('focus', function(){
        window.webkit.messageHandlers.\(JSEventHandler.focus).postMessage({ "messageHandler": "\(JSEventHandler.focus)" });
    });

    document.getElementById('\(ID.editor)').addEventListener('input', function(){
        window.webkit.messageHandlers.\(JSEventHandler.editorChanged).postMessage({ "messageHandler": "\(JSEventHandler.editorChanged)" });
    });

    const observer = new ResizeObserver(entries => {
        for (const entry of entries) {
            console.log(entry.contentRect.height)
            window.webkit.messageHandlers.\(JSEventHandler.bodyResize).postMessage({ "messageHandler": "\(JSEventHandler.bodyResize)", "\(EventAttributeKey.height)": entry.contentRect.height });
        }
    });
    observer.observe(document.querySelector('body'));

    // --------------------
    // Functions
    // --------------------

    \(JSFunction.setFocus.rawValue) = function () {
        document.getElementById('\(ID.editor)').focus();
    };

    \(JSFunction.getHtmlContent.rawValue) = function () {
        return document.getElementById('\(ID.editor)').innerHTML;
    };

    """
    }
}

private extension Color {
    func hexString(in environment: EnvironmentValues) -> String {
        Color(resolve(in: environment).cgColor).toHex()!
    }
}
