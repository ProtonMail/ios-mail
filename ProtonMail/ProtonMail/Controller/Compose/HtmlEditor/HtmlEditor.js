// HtmlEditor.css
// Proton Technologies AG

"use strict";
var html_editor = {};


/// onload
window.onload = function() {
    
};

/// init
html_editor.init = function() {
    
}

/// the editor tag. div
html_editor.editor = document.getElementById('editor');
html_editor.editor_header = document.getElementById('editor_header');

/// cached embed image cids
html_editor.cachedCIDs = "";

/// set html body
html_editor.setHtml = function(htmlBody, sanitizeConfig) {
    var cleanByConfig = DOMPurify.sanitize(htmlBody, sanitizeConfig);
    html_editor.editor.innerHTML = DOMPurify.sanitize(cleanByConfig);
    // could update the viewport width here in the future.
};

/// get the html.
html_editor.getHtml = function() {
    return html_editor.editor.innerHTML;
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
    mvp.setAttribute('content','user-scalable=no, width=' + width + ',initial-scale=1.0, maximum-scale=1.0');
};

/// we don't use it for now.
html_editor.setPlaceholderText = function(text) {
    html_editor.editor.setAttribute("placeholder", text);
};

///
html_editor.editor.addEventListener("input", function() {
    html_editor.delegate("cursor/"+ html_editor.getCaretYPosition());
});

html_editor.getCaretYPosition = function() {
    var sel = window.getSelection();
    // Next line is comented to prevent deselecting selection. It looks like work but if there are any issues will appear then uconmment it as well as code above.
    //sel.collapseToStart();
    var range = sel.getRangeAt(0);
    var span = document.createElement('span');// something happening here preventing selection of elements
    range.collapse(false);
    range.insertNode(span);
    var topPosition = span.offsetTop;
    span.parentNode.removeChild(span);
    return topPosition;
}

//html_editor.getCaretYPosition = function() {
//    var y = 0;
//    var sel = window.getSelection();
//    if (sel.rangeCount) {
//        var range = sel.getRangeAt(0);
//        var needsWorkAround = (range.startOffset == 0)
//        /* Removing fixes bug when node name other than 'div' */
//        // && range.startContainer.nodeName.toLowerCase() == 'div');
//        if (needsWorkAround) {
//            y = range.startContainer.offsetTop - window.pageYOffset;
//        } else {
//            if (range.getClientRects) {
//                var rects=range.getClientRects();
//                if (rects.length > 0) {
//                    y = rects[0].top;
//                }
//            }
//        }
//    }
//
//    return y;
//};

//html_editor.editor.addEventListener("focus", function() {
//  html_editor.delegate("focus")
//});

/// delegate. the swift part could catch the events
html_editor.delegate = function(event) {
    window.location.href = "delegate://" + event
};

//this is for update protonmail email signature
html_editor.updateSignature = function(html, sanitizeConfig) {
    var signature = document.getElementById('protonmail_signature_block');
    var cleanByConfig = DOMPurify.sanitize(html, sanitizeConfig);
    signature.innerHTML = DOMPurify.sanitize(cleanByConfig);
}

html_editor.updateEmbedImage = function(cid, blobdata) {
    var found = document.querySelectorAll('img[src="' + cid + '"]');
    if (found.length) {
        found.forEach(function(image) {
            image.setAttribute('src-original-pm-cid', cid);
            html_editor.cachedCIDs += cid;
            var originalImageData = decodeURIComponent(blobdata);
            image.setAttribute('src', originalImageData);
        });
    }
}

html_editor.removeEmbedImage = function(cid) {
    var found = document.querySelectorAll('img[src-original-pm-cid="' + cid + '"]');
    if (found.length) {
        found.forEach(function(image) {
            image.remove();
        });

    }
}

html_editor.updateHeaderHeight = function(height) {
    html_editor.editor_header.style.height = height + 'px';
}
