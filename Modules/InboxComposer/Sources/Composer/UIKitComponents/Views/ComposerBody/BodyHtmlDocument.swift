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

    enum Event {
        case onContentHeightChange
        case onEditorFocus
        case onEditorChange
        case onCursorPositionChange
    }

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

    enum EventAttributeKey {
        static let height = "height"
        static let cursorPosition = "cursorPosition"
        static let cursorPositionX = "x"
        static let cursorPositionY = "y"
    }

    enum JSFunction: String {
        case setFocus = "html_editor.setFocus"
        case getHtmlContent = "html_editor.getHtmlContent"
        case insertImages = "html_editor.insertImages"

        var callFunction: String {
            "\(self.rawValue)();"
        }
    }

    enum JSEventHandler: String, CaseIterable {
        case bodyResize
        case focus
        case editorChanged
        case cursorPositionChanged

        var event: Event {
            switch self {
            case .bodyResize: .onContentHeightChange
            case .focus: .onEditorFocus
            case .editorChanged: .onEditorChange
            case .cursorPositionChanged: .onCursorPositionChange
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
                /* In the editor, disallow drag, context menu and touch for img */
                #\(ID.editor) img {
                    -webkit-user-drag: none;
                    -webkit-touch-callout: none;
                    pointer-events: none;
                }
                /* In the editor, divs with img as direct children behave like a character to be able to be deleted */
                #\(ID.editor) div:has(> img) {
                    display: inline-block;
                    user-select: contain;
                }
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
    let lastCursorPosition = null;
    let isProcessingNewLine = false;

    // --------------------
    // Event listeners
    // --------------------

    document.getElementById('\(ID.editor)').addEventListener('focus', function(){
        window.webkit.messageHandlers.\(JSEventHandler.focus).postMessage({ "messageHandler": "\(JSEventHandler.focus)" });
    });

    document.getElementById('\(ID.editor)').addEventListener('input', function(event){
        window.webkit.messageHandlers.\(JSEventHandler.editorChanged).postMessage({ "messageHandler": "\(JSEventHandler.editorChanged)" });

        handleUpdateCursorPosition(event);
    });

    const observer = new ResizeObserver(entries => {
        for (const entry of entries) {
            window.webkit.messageHandlers.\(JSEventHandler.bodyResize).postMessage({
                "messageHandler": "\(JSEventHandler.bodyResize)",
                "\(EventAttributeKey.height)": entry.contentRect.height
            });
        }
    });
    observer.observe(document.querySelector('body'));

    // --------------------
    // Public Functions
    // --------------------

    \(JSFunction.setFocus.rawValue) = function () {
        document.getElementById('\(ID.editor)').focus();
    };

    \(JSFunction.getHtmlContent.rawValue) = function () {
        return document.getElementById('\(ID.editor)').innerHTML;
    };

    \(JSFunction.insertImages.rawValue) = function (images) {
        const editor = document.getElementById('\(ID.editor)');
        const selection = window.getSelection();

        const editorHasCursor = document.activeElement === editor && selection.rangeCount;
        if (!editorHasCursor) {
            // Add cursor in editor
            const range = document.createRange();
            range.setStart(editor, 0);
            range.collapse(true);
            selection.removeAllRanges();
            selection.addRange(range);
        }
        
        const html = images.map(function(cid) {
            return `<div><img src="cid:${cid}" style="max-width: 100%;"></div><br>`;
        }).join('');

        document.execCommand('insertHTML', false, html);
        editor.dispatchEvent(new Event('input'));
    };

    // --------------------
    // Private Functions
    // --------------------

    function handleUpdateCursorPosition(event) {
        var isEnterKeyPress = event.inputType === 'insertParagraph';
        if (isEnterKeyPress && !isProcessingNewLine) {
            isProcessingNewLine = true;

            // wait until next render to ensure all layout changes are done
            requestAnimationFrame(() => {
                const position = getCursorCoordinates();
                if (position) {
                    window.webkit.messageHandlers.\(JSEventHandler.cursorPositionChanged).postMessage({
                        "messageHandler": "\(JSEventHandler.cursorPositionChanged)",
                        "\(EventAttributeKey.cursorPosition)": {
                            "\(EventAttributeKey.cursorPositionX)": position.x,
                            "\(EventAttributeKey.cursorPositionY)": position.y
                        }
                    });
                }
                isProcessingNewLine = false;
            });
        } else if (!isProcessingNewLine) {
            updateCursorPosition();
        }
    }

    /**
     * Retrieves the cursor's position.
     *
     * This function works by temporarily inserting a zero-width character (`\\u200b`) at the cursor's
     * current position, then measuring the position of that character. The temporary span is removed
     * afterward, and the selection is restored to its original state.
     */
    function getCursorCoordinates() {
        const selection = window.getSelection();
        if (!selection.rangeCount) return null;

        const range = selection.getRangeAt(0);
        if (!range.collapsed) return null;

        // Create a temporary span with a zero-width character
        const span = document.createElement('span');
        span.appendChild(document.createTextNode('\\u200b'));
        
        // Insert the span
        range.insertNode(span);
        
        // Get position
        const rect = span.getBoundingClientRect();
        
        // Remove the span but keep the selection
        const parent = span.parentNode;
        const next = span.nextSibling;
        parent.removeChild(span);
        
        // Restore selection
        const newRange = document.createRange();
        newRange.setStart(next || parent, 0);
        newRange.collapse(true);
        selection.removeAllRanges();
        selection.addRange(newRange);
        
        return {x: rect.x, y: rect.y};
    }

    function updateCursorPosition() {
        const position = getCursorCoordinates();
        if (!position) return;
        
        const newPosition = JSON.stringify(position);
        if (newPosition !== lastCursorPosition) {
            lastCursorPosition = newPosition;
            window.webkit.messageHandlers.\(JSEventHandler.cursorPositionChanged).postMessage({
                "messageHandler": "\(JSEventHandler.cursorPositionChanged)",
                "\(EventAttributeKey.cursorPosition)": position
            });
        }
    }

    """
    }
}

private extension Color {
    func hexString(in environment: EnvironmentValues) -> String {
        Color(resolve(in: environment).cgColor).toHex()!
    }
}
