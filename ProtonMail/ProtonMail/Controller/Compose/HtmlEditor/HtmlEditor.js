// HtmlEditor.css
// Proton Technologies AG

"use strict";
var html_editor = {};


/// onload
window.onload = function() {

};

/// init
html_editor.init = function() {

};

/// the editor tag. div
html_editor.editor = document.getElementById('editor');
html_editor.editor_header = document.getElementById('editor_header');

/// track changes in DOM tree
var mutationObserver = new MutationObserver(function(events) {
    var insertedImages = false;

    for (var i = 0; i < events.length; i++) {
        var event = events[i];

        // check if removed image was our inline embedded attachment
        for (var j = 0; j < event.removedNodes.length; j++) {
            var removedNode = event.removedNodes[j];
            if (removedNode.nodeType === Node.ELEMENT_NODE && removedNode.tagName != 'CARET') {
                if (removedNode.getAttribute('src-original-pm-cid')) {
                    var cidWithPrefix = removedNode.getAttribute('src-original-pm-cid');
                    var cid = cidWithPrefix.replace("cid:", "");
                    window.webkit.messageHandlers.removeImage.postMessage({ "messageHandler": "removeImage", "cid": cid });
                }
            }
        }

        // find all img in inserted nodes and update height once they are loaded
        for (var k = 0; k < event.addedNodes.length; k++) {
            var element = event.addedNodes[k];
            if (element.nodeType === Node.ELEMENT_NODE && element.tagName != 'CARET') {
                var spotImg = function(img) {
                    insertedImages = true;
                    img.onload = function() {
                        var contentsHeight = html_editor.getContentsHeight();
                        window.webkit.messageHandlers.heightUpdated.postMessage({ "messageHandler": "heightUpdated", "height": contentsHeight });
                    };
                };

                if (element.tagName == 'IMG') {
                    spotImg(element);
                    continue;
                }

                var children = Array.from(element.querySelectorAll('img'));
                for (var m = 0; m < children.length; m++) {
                    spotImg(children[m]);
                }
            }
        }
    }

    if (insertedImages) {
        // update height if some cached img were inserted which will never have onload called
        var contentsHeight = html_editor.getContentsHeight();
        window.webkit.messageHandlers.heightUpdated.postMessage({ "messageHandler": "heightUpdated", "height": contentsHeight });

        // process new inline images
        html_editor.acquireEmbeddedImages();
    }
});
mutationObserver.observe(html_editor.editor, { childList: true, subtree: true });

/// cached embed image cids
html_editor.cachedCIDs = {};

/// set html body
html_editor.setHtml = function(htmlBody, sanitizeConfig) {
    var cleanByConfig = DOMPurify.sanitize(htmlBody, sanitizeConfig);
    html_editor.editor.innerHTML = DOMPurify.sanitize(cleanByConfig);
    // could update the viewport width here in the future.
};

/// get the html. first removes embedded blobs, then takes the html, then puts embedded stuff back
html_editor.getHtml = function() {
    for (var cid in html_editor.cachedCIDs) {
        html_editor.hideEmbedImage(cid);
    }
    var emptyHtml = html_editor.editor.innerHTML;
    for (var cid in html_editor.cachedCIDs) {
        html_editor.updateEmbedImage(cid, html_editor.cachedCIDs[cid]);
    }
    return emptyHtml;
};

/// get clear test
html_editor.getText = function() {
    return html_editor.editor.innerText;
};

html_editor.setCSP = function(content) {
    var mvp = document.getElementById('myCSP');
    mvp.setAttribute('content', content);
};

/// update view port width. set to the content size otherwise the text selection will not work
html_editor.setWidth = function(width) {
    var mvp = document.getElementById('myViewport');
    mvp.setAttribute('content', 'user-scalable=no, width=' + width + ',initial-scale=1.0, maximum-scale=1.0');
};

/// we don't use it for now.
html_editor.setPlaceholderText = function(text) {
    html_editor.editor.setAttribute("placeholder", text);
};

/// transmits caret position to the app
html_editor.editor.addEventListener("input", function() { // input and not keydown/keyup/keypress cuz need to move caret when inserting text via autocomplete too
    html_editor.getCaretYPosition();
});

html_editor.editor.addEventListener("drop", function(event) {
    var items = event.dataTransfer.items;
    html_editor.absorbImage(event, items, event.target);
});

html_editor.editor.addEventListener("paste", function(event) {
    var items = event.clipboardData.items;
    html_editor.absorbImage(event, items, window.getSelection().getRangeAt(0).commonAncestorContainer);
});

/// cathes pasted images to turn them into data blobs and add as attachments
html_editor.absorbImage = function(event, items, target) {
        for (var m = 0; m < items.length; m++) { 
            var file = items[m].getAsFile();
            if (file == undefined || file == null) {
                continue;
            }
            event.preventDefault(); // prevent default only if a file is pasted

            html_editor.getBase64FromFile(file, function(base64) {
                var name = html_editor.createUUID() + "_" + file.name;
                var bits = "data:" + file.type + ";base64," + base64;
                var img = new Image();
                target.appendChild(img);
                html_editor.setImageData(img, "cid:" + name, bits);
                
                window.webkit.messageHandlers.addImage.postMessage({ "messageHandler": "addImage", "cid": name, "data": base64 });
            });
        }
};

/// breaks the blockquote into two if possible
html_editor.editor.addEventListener("keydown", function(key) {
    quote_breaker.breakQuoteIfNeeded(key);
});

html_editor.caret = document.createElement('caret'); // something happening here preventing selection of elements
html_editor.getCaretYPosition = function() {
    var range = window.getSelection().getRangeAt(0);
    if (html_editor.caret != range.endContainer.nextElementSibling) {
        range.collapse(false);
        range.insertNode(html_editor.caret);
    }

    // relative to the viewport, while offsetTop is relative to parent, which differs when editing the quoted message text
    var rect = html_editor.caret.getBoundingClientRect();
    var leftPosition = rect.left + window.scrollX;
    var topPosition = rect.top + window.scrollY;
    var contentsHeight = html_editor.getContentsHeight();

    window.webkit.messageHandlers.moveCaret.postMessage({ "messageHandler": "moveCaret", "cursorX": leftPosition, "cursorY": topPosition, "height": contentsHeight });
}

//this is for update protonmail email signature
html_editor.updateSignature = function(html, sanitizeConfig) {
    var signature = document.querySelector('div.protonmail_signature_block');
    if (!signature) {
        return
    }
    var cleanByConfig = DOMPurify.sanitize(html, sanitizeConfig);
    signature.innerHTML = DOMPurify.sanitize(cleanByConfig);
}

// for calls from Swift
html_editor.updateEncodedEmbedImage = function(cid, blobdata) {
    var found = document.querySelectorAll('img[src="' + cid + '"]');
    for (var i = 0; i < found.length; i++) {
        var originalImageData = decodeURIComponent(blobdata);
        html_editor.setImageData(found[i], cid, originalImageData);
    }
}

// for calls from JS
html_editor.updateEmbedImage = function(cid, blobdata) {
    var found = document.querySelectorAll('img[src="' + cid + '"]');
    for (var i = 0; i < found.length; i++) {
        html_editor.setImageData(found[i], cid, blobdata);
    }
}

html_editor.hideEmbedImage = function(cid) {
    var found = document.querySelectorAll('img[src-original-pm-cid="' + cid + '"]');
    for (var i = 0; i < found.length; i++) {
        found[i].setAttribute('src', cid);
    }
}

html_editor.setImageData = function(image, cid, blobdata) {
    image.setAttribute('src-original-pm-cid', cid);
    html_editor.cachedCIDs[cid] = blobdata;
    image.setAttribute('src', blobdata);
    image.class = 'proton-embedded';
}

html_editor.acquireEmbeddedImages = function() {
    var found = document.querySelectorAll('img[src^="blob:null"], img[src^="webkit-fake-url://"]');
    for (var i = 0; i < found.length; i++) {
        html_editor.getBase64FromImageUrl(found[i], function(oldImage, cid, data) {
            html_editor.setImageData(oldImage, "cid:" + cid, data);
            var bits = data.replace(/data:image\/[a-z]+;base64,/, '');
            window.webkit.messageHandlers.addImage.postMessage({ "messageHandler": "addImage", "cid": cid, "data": bits });
        });
    }
}

html_editor.getBase64FromImageUrl = function(oldImage, callback) {
    var img = new Image();
    img.onload = function(e) {        
        var canvas = document.createElement("canvas");

        // Canvas has a limitation for maximum image size, different for every device.
        // Since we do not want receiver to know which device the message was written on,
        // we'll stick to one the oldest supported - iPhone 5 - which is 3 Mp.
        // (according to SO: https://stackoverflow.com/a/23391599/4751521)
        var sizeLimit = 3 * 1024 * 1024;
        if (this.width * this.height < sizeLimit) {
            canvas.width = this.width;
            canvas.height = this.height;
        } else {
            var coefficient = Math.sqrt(sizeLimit / (this.height * this.width));
            canvas.width = coefficient * this.width;
            canvas.height = coefficient * this.height;
        }

        var ctx = canvas.getContext("2d");
        ctx.drawImage(this, 0, 0, canvas.width, canvas.height);

        var data = canvas.toDataURL("image/png");
        var cid = oldImage.src.replace("blob:null\/", '');
        callback(oldImage, cid + ".png", data);
    };
   img.src = oldImage.src;
}

html_editor.removeEmbedImage = function(cid) {
    var found = document.querySelectorAll('img[src-original-pm-cid="' + cid + '"]');
    for (var i = 0; i < found.length; i++) {
        found[i].remove();
    }
}

html_editor.getContentsHeight = function() {
    var rects = document.body.getBoundingClientRect();
    return rects.height;
}

html_editor.getBase64FromFile = function(file, callback) {
    var reader = new FileReader();
    reader.onloadend = function(e) {
        var binary = '';
        var bytes = new Uint8Array(e.target.result);
        var len = bytes.byteLength;
        for (var i = 0; i < len; i++) {
            binary += String.fromCharCode( bytes[ i ] );
        }
        var base64 = window.btoa( binary );
        return callback(base64);
    };
    reader.readAsArrayBuffer(file);
}

html_editor.createUUID = function() {
    // https://stackoverflow.com/a/873856
    // http://www.ietf.org/rfc/rfc4122.txt
    var s = [];
    var hexDigits = "0123456789abcdef";
    for (var i = 0; i < 36; i++) {
        s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1);
    }
    s[14] = "4";  // bits 12-15 of the time_hi_and_version field to 0010
    s[19] = hexDigits.substr((s[19] & 0x3) | 0x8, 1);  // bits 6-7 of the clock_seq_hi_and_reserved to 01
    s[8] = s[13] = s[18] = s[23] = "-";

    var uuid = s.join("");
    return uuid;
}

html_editor.formattingTags = ['b', 'strong', 'i', 'em', 'mark', 'u', 'sub', 'sup', 'del', 'ins', 'big', 'small'];
html_editor.clearNodeStyling = function(node) {
    if (node.removeAttribute) {
        node.removeAttribute("style");
    }

    if (html_editor.formattingTags.indexOf(node.nodeName.toLowerCase()) != -1) { 
        // replace parent with its inner value
        var span = document.createElement('span');
        span.innerHTML = node.innerHTML;
        node.parentElement.replaceChild(span, node);
    }
}

html_editor.removeStyleFromSelection = function() {
    var selection = window.getSelection().getRangeAt(0).commonAncestorContainer;

    // clear all parents
    var current = selection;
    while (current != null && current != undefined) {
        var parent = current.parentElement;
        html_editor.clearNodeStyling(current);
        current = parent;
    }

    // clear all children of first ancestor
    var siblings = selection.querySelectorAll("*");
    for (var i = siblings.length - 1; i >= 0 ; i--) {
        html_editor.clearNodeStyling(siblings[i]);
    }
}

