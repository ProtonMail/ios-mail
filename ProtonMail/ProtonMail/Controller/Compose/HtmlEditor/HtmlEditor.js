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
    mvp.setAttribute('content','user-scalable=no, width=' + width + ',initial-scale=1.0, maximum-scale=1.0');
};

/// we don't use it for now.
html_editor.setPlaceholderText = function(text) {
    html_editor.editor.setAttribute("placeholder", text);
};

/// transmits caret position to the app
html_editor.editor.addEventListener("input", function() {
    html_editor.delegate("cursor/"+ html_editor.getCaretYPosition());
    html_editor.acquireEmbeddedImages();
});

/// breaks the blockquote into two if possible
html_editor.editor.addEventListener("keydown", function(key) {
    quote_breaker.breakQuoteIfNeeded(key);
});

html_editor.getCaretYPosition = function() {
    var sel = window.getSelection();
    // Next line is comented to prevent deselecting selection. It looks like work but if there are any issues will appear then uconmment it as well as code above.
    //sel.collapseToStart();
    var range = sel.getRangeAt(0);
    var span = document.createElement('span');// something happening here preventing selection of elements
    range.collapse(false);
    range.insertNode(span);
    
    // relative to the viewport, while offsetTop is relative to parent, which differs when editing the quoted message text
    var rect = span.getBoundingClientRect();
    var leftPosition = rect.left + window.scrollX;
    var topPosition = rect.top + window.scrollY;
    
    span.parentNode.removeChild(span);
    return [leftPosition, topPosition];
}

/// delegate. the swift part could catch the events
html_editor.delegate = function(event) {
    window.webkit.messageHandlers.moveCaret.postMessage({ "delegate": "delegate://" + event });
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
            html_editor.setImageData(image, cid, blobdata);
        });
    }
}

html_editor.hideEmbedImage = function(cid) {
    var found = document.querySelectorAll('img[src-original-pm-cid="' + cid + '"]');
    if (found.length) {
        found.forEach(function(image) {
                      image.setAttribute('src', cid);
                      });
    }
}

html_editor.setImageData = function(image, cid, blobdata) {
    image.setAttribute('src-original-pm-cid', cid);
    html_editor.cachedCIDs[cid] = blobdata;
    image.setAttribute('src', blobdata);
}

html_editor.acquireEmbeddedImages = function() {
    var found = document.querySelectorAll('img[src^="blob:null"]');
    if (found.length) {
        found.forEach(function(image) {
            html_editor.getBase64FromImageUrl(image.src, function(url, data) {
                html_editor.setImageData(image, url, data);
                var bits = data.replace(/data:image\/[a-z]+;base64,/, '');
                window.webkit.messageHandlers.addImage.postMessage({ "url": url, "data": bits });
            });
        });
    }
}

html_editor.getBase64FromImageUrl = function(url, callback) {
    var img = new Image();
    img.onload = function () {
        var canvas = document.createElement("canvas");
        canvas.width = this.width;
        canvas.height = this.height;
        
        var ctx = canvas.getContext("2d");
        ctx.drawImage(this, 0, 0);
        
        var data = canvas.toDataURL("image/png");
        callback(url, data);
    };
    img.src = url;
}

html_editor.removeEmbedImage = function(cid) {
    var found = document.querySelectorAll('img[src-original-pm-cid="' + cid + '"]');
    if (found.length) {
        found.forEach(function(image) {
            image.remove();
        });

    }
}

