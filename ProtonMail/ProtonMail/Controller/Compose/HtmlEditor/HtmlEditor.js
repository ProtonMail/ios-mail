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
html_editor.setHtml = function(htmlBody) {
    html_editor.editor.innerHTML = htmlBody;
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
//html_editor.editor.addEventListener("input", function() {
//                                    html_editor.delegate("input");
//                                    });


//html_editor.editor.addEventListener("focus", function() {
//                                    //RE.backuprange();
//                                    html_editor.delegate("focus")
//                                    });

/// delegate. the swift part could catch the events
html_editor.delegate = function(event) {
    window.location.href = "delegate://" + event
};

//this is for update protonmail email signature
html_editor.updateSignature = function(html) {
    var signature = document.getElementById('protonmail_signature_block');
    signature.innerHTML = html
}

html_editor.updateEmbedImage = function(cid, blobdata) {
    var found = document.querySelectorAll('img[src="' + cid + '"]');
    if (found.length) {
        found.forEach(function(image) {
            image.setAttribute('src-original-pm-cid', cid);
//            image.createAttribute(
//                      var att = document.createAttribute("href");
//                      att.value = "https://www.w3schools.com";
//                      anchor.setAttributeNode(att);
//            image.attr('src-original-pm-cid', cid);
            html_editor.cachedCIDs += cid;
            image.setAttribute('src', blobdata);
        });
    }
}

html_editor.removeEmbedImage = function(cid) {
    var editor = $('img[src-original-pm-cid="' + cid + '"]');
    if (editor.length) {
        editor.each(function(index, e) {
            var image = $(this);
            image.remove();
        });
    }
}

html_editor.updateHeaderHeight = function(height) {
    html_editor.editor_header.style.height = height + 'px';
}
