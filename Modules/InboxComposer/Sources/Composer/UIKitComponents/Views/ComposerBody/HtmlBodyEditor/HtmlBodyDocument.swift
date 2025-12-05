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
import SwiftUI
import proton_app_uniffi

struct HtmlBodyDocument {
    private let css: String = {
        let fileURL = Bundle.module.url(forResource: "BodyHtmlStyling", withExtension: "css")!
        return try! String(contentsOf: fileURL)
    }()

    func html(content: ComposerContent) -> String {
        htmlTemplate
            .replacingOccurrences(of: HtmlPlaceholder.body, with: content.body)
            .replacingOccurrences(of: HtmlPlaceholder.css, with: css)
            .replacingOccurrences(of: HtmlPlaceholder.sdkHeadContent, with: content.head)
    }
}

extension HtmlBodyDocument {
    enum EventAttributeKey {
        static let height = "height"
        static let cursorPosition = "cursorPosition"
        static let cursorPositionX = "x"
        static let cursorPositionY = "y"
        static let imageData = "imageData"
        static let text = "text"
    }

    enum JSEvent: String, CaseIterable {
        case bodyResize
        case focus
        case editorChanged
        case cursorPositionChanged
        case inlineImageRemoved
        case inlineImageTapped
        case imagePasted
        case textPasted
    }

    enum JSFunction: String {
        case setFocus = "html_editor.setFocus"
        case getHtmlContent = "html_editor.getHtmlContent"
        case insertHtmlAtCurrentPosition = "html_editor.insertHtmlAtCurrentPosition"
        case removeImageWithCID = "html_editor.removeImageWithCID"

        var callFunction: String {
            "\(self.rawValue)();"
        }
    }
}

extension HtmlBodyDocument {
    enum ID {
        static let editor = "editor"
    }
}

// MARK: Private

private extension HtmlBodyDocument {
    enum HtmlPlaceholder {
        static let body = "<!--INSERT_BODY-->"
        static let css = "<!--CSS-->"
        static let sdkHeadContent = "<!--SDK_HEAD_CONTENT-->"
    }
}

// MARK: HTML

private extension HtmlBodyDocument {
    var htmlTemplate: String {
        """
        <!DOCTYPE html>
        <html lang="en">
            <head>
                <title>Proton HTML Editor</title>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, shrink-to-fit=yes">
                <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
                \(HtmlPlaceholder.sdkHeadContent)
                <style>
                    \(HtmlPlaceholder.css)
                    /* In the editor, disable drag and drop and contextual menus for images */
                    #\(ID.editor) img {
                        -webkit-user-drag: none;
                        -webkit-touch-callout: none;
                        -webkit-user-select: none;
                        -webkit-tap-highlight-color: transparent;
                        user-select: none;
                        pointer-events: all;
                        cursor: pointer;
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
            </body>
        </html>
        """
    }
}

// MARK: Scripts

extension HtmlBodyDocument {
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
            window.webkit.messageHandlers.\(JSEvent.focus).postMessage({ "messageHandler": "\(JSEvent.focus)" });
        });

        document.getElementById('\(ID.editor)').addEventListener('input', function(event){
            window.webkit.messageHandlers.\(JSEvent.editorChanged).postMessage({ "messageHandler": "\(JSEvent.editorChanged)" });

            handleUpdateCursorPosition(event);
        });

        const resizeObserver = new ResizeObserver(entries => {
            notifyHeightChange();
        });
        resizeObserver.observe(document.getElementById('\(ID.editor)'));

        const removeInlinImageObserver = new MutationObserver(mutations => {
            mutations.forEach(mutation => {
                if (mutation.type === 'childList') {
                    mutation.removedNodes.forEach(node => {
                        if (node.nodeName === 'IMG') {
                            const src = node.getAttribute('src');
                            if (src && src.startsWith('cid:')) {
                                const cid = src.substring(4);
                                window.webkit.messageHandlers.\(JSEvent.inlineImageRemoved).postMessage({
                                    "messageHandler": "\(JSEvent.inlineImageRemoved)",
                                    "cid": cid
                                });
                            }
                        }
                    });
                }
            });
        });
        removeInlinImageObserver.observe(document.getElementById('\(ID.editor)'), {childList: true, subtree: true});

        document.getElementById('\(ID.editor)').addEventListener('click', function(event) {
            if (event.target.nodeName === 'IMG') {
                const src = event.target.getAttribute('src');
                if (src && src.startsWith('cid:')) {
                    const img = event.target;
                    const rect = img.getBoundingClientRect();
                    const width  = rect.width;
                    const height = rect.height;
                    const x = rect.left + window.scrollX;  
                    const y = rect.top  + window.scrollY;  

                    const cid = src.substring(4);

                    window.webkit.messageHandlers.\(JSEvent.inlineImageTapped).postMessage({
                        "messageHandler": "\(JSEvent.inlineImageTapped)",
                        "cid": cid,
                        "x": x,
                        "y": y,
                        "width": width,
                        "height": height
                    });
                }
            }
        });

        document.addEventListener('drop', function(event) {
            event.preventDefault();
            event.stopPropagation();
        });

        document.addEventListener('dragover', function(event) {
            event.preventDefault();
            event.stopPropagation();
        });

        document.getElementById('\(ID.editor)').addEventListener('paste', function(event) {
            // We intercept and cancel the paste event to handle it ourselves
            event.preventDefault();

            const cd = (event.clipboardData || event.originalEvent?.clipboardData);
            const items = Array.from(cd?.items || []);

            // Handle image files (can be multiple)
            items.forEach(item => {
                if (item.kind === 'file') {
                    handleFilePaste(item);
                }
            });

            // Prefer HTML text over plain text, post only once
            const htmlItem = items.find(item => item.kind === 'string' && item.type === 'text/html');
            const plainItem = items.find(item => item.kind === 'string' && item.type === 'text/plain');
            const chosenTextItem = htmlItem || plainItem;
            if (chosenTextItem) {
                handleTextPaste(chosenTextItem);
            }

            // Pasting could push some content above the visible area of the editor, to avoid 
            // this we reset scrolling attributes. 
            setTimeout(() => {
                resetAllScrollPositions();
                notifyHeightChange();
            }, 20);
        });

        function handleFilePaste(item) {
            const file = item.getAsFile();
            if (!file.type.startsWith("image/")) { return; }
            const reader = new FileReader();
            reader.onload = function(event) {

                const base64data = event.target.result.split(',')[1];
                window.webkit.messageHandlers.\(JSEvent.imagePasted).postMessage({
                    "messageHandler": "\(JSEvent.imagePasted)",
                    "\(EventAttributeKey.imageData)": base64data
                });
            };
            reader.readAsDataURL(file);
        }

        function handleTextPaste(item) {
            item.getAsString((text) => {
                window.webkit.messageHandlers.\(JSEvent.textPasted).postMessage({
                    "messageHandler": "\(JSEvent.textPasted)",
                    "\(EventAttributeKey.text)": text
                });
            });
        }

        // --------------------
        // Public Functions
        // --------------------

        \(JSFunction.setFocus.rawValue) = function () {
            document.getElementById('\(ID.editor)').focus();
        };

        \(JSFunction.getHtmlContent.rawValue) = function () {
            return document.getElementById('\(ID.editor)').innerHTML;
        };

        \(JSFunction.insertHtmlAtCurrentPosition.rawValue) = function (html) {
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

            document.execCommand('insertHTML', false, html);
            editor.dispatchEvent(new Event('input'));

            const allImages = editor.getElementsByTagName('img');
            waitForImagesLoaded(allImages).then(() => {
                requestAnimationFrame(() => {
                    updateCursorPosition();
                });
            });
        };

        \(JSFunction.removeImageWithCID.rawValue) = function (cid) {
            const editor = document.getElementById('\(ID.editor)');
            const images = editor.getElementsByTagName('img');
            const exactCidPattern = 'cid:' + cid + '(?![0-9a-zA-Z])'; // Matches exact CID
            const cidRegex = new RegExp(exactCidPattern);
            
            for (let i = images.length - 1; i >= 0; i--) {
                const img = images[i];
                const attributes = img.attributes;
                
                for (let j = 0; j < attributes.length; j++) {
                    const attr = attributes[j];
                    if (cidRegex.test(attr.value)) {
                        img.remove();
                        break;
                    }
                }
            }
            
            editor.dispatchEvent(new Event('input'));
        };

        // --------------------
        // Private Functions
        // --------------------

        function notifyHeightChange() {
            const editor = document.getElementById('\(ID.editor)');
            // editor.scrollHeight: The total height of all content in the editor
            // editor.offsetHeight: The visible height of the editor component as currently rendered
            // we want offsetHeight when the content is shorter than the actual component
            const height = Math.max(editor.scrollHeight, editor.offsetHeight);
            
            window.webkit.messageHandlers.\(JSEvent.bodyResize).postMessage({
                "messageHandler": "\(JSEvent.bodyResize)",
                "\(EventAttributeKey.height)": height
            });
        }

        function handleUpdateCursorPosition(event) {
            var isEnterKeyPress = event.inputType === 'insertParagraph';
            if (isEnterKeyPress && !isProcessingNewLine) {
                isProcessingNewLine = true;

                // wait until next render to ensure all layout changes are done
                requestAnimationFrame(() => {
                    debouncedUpdateCursorPosition();
                    isProcessingNewLine = false;
                });
            } else if (!isProcessingNewLine) {
                debouncedUpdateCursorPosition();
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

            // Get the node at cursor position
            const node = range.startContainer;
            const offset = range.startOffset;

            // Create a temporary span with a zero-width character
            const span = document.createElement('span');
            span.appendChild(document.createTextNode('\\u200b'));
            
            // Insert the span
            range.insertNode(span);
            
            // Get position
            let rect = span.getBoundingClientRect();
            
            // If we got a zero position and we're at the start/end of a node,
            // try to get position from adjacent content
            if (rect.y === 0) {
                const previousNode = node.previousSibling;
                const nextNode = node.nextSibling;
                
                if (offset === 0 && previousNode) {
                    // Try to get position from end of previous node
                    rect = previousNode.getBoundingClientRect();
                    if (rect.y !== 0) {
                        rect = {x: rect.x, y: rect.bottom};
                    }
                } else if (offset === node.length && nextNode) {
                    // Try to get position from start of next node
                    rect = nextNode.getBoundingClientRect();
                }
            }
            
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
            
            // Only return position if we actually found one
            return rect.y === 0 ? null : {x: rect.x, y: rect.y};
        }

        function updateCursorPosition() {
            const position = getCursorCoordinates();
            if (!position) return;
            
            if (position) {
                window.webkit.messageHandlers.\(JSEvent.cursorPositionChanged).postMessage({
                    "messageHandler": "\(JSEvent.cursorPositionChanged)",
                    "\(EventAttributeKey.cursorPosition)": {
                        "\(EventAttributeKey.cursorPositionX)": position.x,
                        "\(EventAttributeKey.cursorPositionY)": position.y
                    }
                });
            }
        }

        function waitForImagesLoaded(images) {
            return Promise.all(Array.from(images).map(img => {
                if (img.complete) {
                    return Promise.resolve();
                }
                return new Promise(resolve => {
                    img.onload = resolve;
                    img.onerror = resolve; // Handle load errors gracefully
                });
            }));
        }

        // The composer scrolls by increaing the height of the UIKit container, therefore resetting
        // scroll positions won't have any visible effect for the user.
        function resetAllScrollPositions() {
            const editor = document.getElementById('\(ID.editor)');
            editor.scrollTop = 0;
            editor.scrollLeft = 0;
            document.documentElement.scrollTop = 0;
            document.documentElement.scrollLeft = 0;
            document.body.scrollTop = 0;
            document.body.scrollLeft = 0;
            window.scrollTo(0, 0);
        }

        function debounce(func, wait) {
            let timeout;
            return function(...args) {
                clearTimeout(timeout);
                timeout = setTimeout(() => func.apply(this, args), wait);
            };
        }

        const debouncedUpdateCursorPosition = debounce(updateCursorPosition, 100);
        """
    }
}

private extension Color {
    func hexString(in environment: EnvironmentValues) -> String {
        Color(resolve(in: environment).cgColor).toHex()!
    }
}
