// HtmlEditor.js
// Proton AG

"use strict";
var html_editor = {};

/// the editor tag. div
html_editor.editor = document.getElementById('editor');
html_editor.editor_header = document.getElementById('editor_header');

/// track changes in DOM tree
var mutationObserver = new MutationObserver(function (events) {
    var insertedImages = false;

    for (var i = 0; i < events.length; i++) {
        var event = events[i];
        event.target.setAttribute("dir", "auto");
        // check if removed image was our inline embedded attachment
        for (var j = 0; j < event.removedNodes.length; j++) {
            var removedNode = event.removedNodes[j];
            if (removedNode.nodeType !== Node.ELEMENT_NODE || removedNode.tagName === 'CARET') {
                continue
            }
            if (removedNode.tagName === 'DIV' && html_editor.editor.querySelectorAll('div').length === 0) {
                // Add div back when all of divs in the html_editor.editor are removed
                let div1 = document.createElement('div')
                div1.innerHTML = '<br>'
                let div2 = document.createElement('div')
                div2.innerHTML = '<br>'
                html_editor.editor.appendChild(div1);
                html_editor.editor.appendChild(div2);

                // Move cursor to newly created div
                let range = new Range();
                range.setStart(div1, 0);
                range.setEnd(div1, 0);
                document.getSelection().removeAllRanges();
                document.getSelection().addRange(range);
            } else if (removedNode.getAttribute('src-original-pm-cid')) {
                var cidWithPrefix = removedNode.getAttribute('src-original-pm-cid');
                var cid = cidWithPrefix.replace(/^(cid:|proton-cid:)/,"");
                console.log("Trying to remove image with cid " + cid);

                const imgsContainingThisImage = document.querySelectorAll('img[src-original-pm-cid="' + cid + '"]');
                console.log("Image is referenced by " + imgsContainingThisImage.length + " nodes");

                if (imgsContainingThisImage.length == 0) {
                    window.webkit.messageHandlers.removeImage.postMessage({ "messageHandler": "removeImage", "cid": cid });
                }
            }
        }

        // find all img in inserted nodes and update height once they are loaded
        for (var k = 0; k < event.addedNodes.length; k++) {
            var element = event.addedNodes[k];
            if (element.nodeType === Node.ELEMENT_NODE && element.tagName != 'CARET') {
                if (element.tagName == 'IMG') {
                    element.setAttribute('draggable', 'false')
                    insertedImages = true;
                    continue;
                }
            }
        }
    }

    if (insertedImages) {
        // process new inline images
        html_editor.acquireEmbeddedImages();
    }
});
mutationObserver.observe(html_editor.editor, { childList: true, subtree: true });

/// cached embed image cids
html_editor.cachedCIDs = {};

/// set html body
html_editor.setHtml = function (htmlBody, sanitizeConfig, isImageProxyEnable) {
    if (isImageProxyEnable) {
        DOMPurify.clearConfig();
        DOMPurify.addHook('beforeSanitizeElements', html_editor.beforeSanitizeElements);
        var cleanByConfig = DOMPurify.sanitize(htmlBody, sanitizeConfig);
        html_editor.editor.innerHTML = cleanByConfig.innerHTML;
        DOMPurify.removeHook('beforeSanitizeElements');
    } else {
        var cleanByConfig = DOMPurify.sanitize(htmlBody, sanitizeConfig);
        html_editor.editor.innerHTML = DOMPurify.sanitize(cleanByConfig);
    }

    // Sometimes ResizeObserver doesn't get correct height
    let scrollHeight = document.body.scrollHeight;
    window.webkit.messageHandlers.heightUpdated.postMessage({ "messageHandler": "heightUpdated", "height": scrollHeight });

    // could update the viewport width here in the future.

    let arr = document.querySelectorAll('div.signature_br')
    arr.forEach(ele => ele.setAttribute('contentEditable', 'false'))
};

/// get the html. first removes embedded blobs, remove the proton prefix and return html, then puts embedded stuff back
html_editor.getHtmlForDraft = function () {
    let duplicatedDocument = document.cloneNode(true)
    for (var cid in html_editor.cachedCIDs) {
        html_editor.hideEmbedImageIn(duplicatedDocument, cid)
    }

    const { matchedElements, hasRemoteImages } = html_editor.getRemoteImageMatches(duplicatedDocument);

    matchedElements.forEach((match) => {
        let url = '';
        let matchedAttribute = '';
        ATTRIBUTES_TO_LOAD.some((attribute) => {
            url = match.getAttribute(`${attribute}`) || '';
            matchedAttribute = attribute;
            return url && url !== '';
        });

        if (url && url !== '' && matchedAttribute && matchedAttribute !== '') {
            var attribute = match.getAttribute(matchedAttribute);
            var newAttribute = attribute.replace(/^proton-/, '');

            if (newAttribute !== null) {
                match.setAttribute(matchedAttribute, newAttribute);
            }
            return;
        }

        if (!url && match.hasAttribute('style') && match.getAttribute('style').includes('proton-url')) {
            const styleContent = match.getAttribute('style');
            if (styleContent !== null) {
                const originalUrl = styleContent.match(/proton-url\((.*?)\)/)[1].replace(/('|")/g, '');
                if (originalUrl) {
                    match.removeAttribute('style');
                    match.setAttribute('style', originalUrl);
                }
            }
        }
    });

    const duplicatedEditor = duplicatedDocument.getElementById('editor');
    const htmlWithoutEmbeddedImagesAfterProcess = duplicatedEditor.innerHTML;
    return htmlWithoutEmbeddedImagesAfterProcess;
};

html_editor.getRawHtml = function () {
    for (var cid in html_editor.cachedCIDs) {
        html_editor.hideEmbedImage(document, cid);
    }

    var emptyHtml = html_editor.editor.innerHTML;

    // Add embedded images back
    for (var cid in html_editor.cachedCIDs) {
        html_editor.updateEmbedImage(cid, html_editor.cachedCIDs[cid]);
    }
    return emptyHtml;
};

/// get clear test
html_editor.getText = function () {
    return html_editor.editor.innerText;
};

html_editor.setCSP = function (content) {
    var mvp = document.getElementById('myCSP');
    mvp.setAttribute('content', content);
};

html_editor.addSupplementCSS = function (css) {
    let style = document.createElement(`style`);
    style.textContent = css;
    document.head.appendChild(style);
};

/// transmits caret position to the app
html_editor.editor.addEventListener("input", function () { // input and not keydown/keyup/keypress cuz need to move caret when inserting text via autocomplete too
    html_editor.getCaretYPosition();
});

html_editor.editor.addEventListener("paste", function (event) {
    var items = event.clipboardData.items;
    html_editor.absorbContactGroupPaste(event);
    html_editor.absorbImage(event, items, window.getSelection().getRangeAt(0).commonAncestorContainer);
    html_editor.handlePastedData(event);
});

html_editor.editor.addEventListener("click", function (event) {
    if (event.target && event.target.tagName === "IMG" && event.target.hasAttribute('src-original-pm-cid')) {
        let cid = event.target.getAttribute('src-original-pm-cid');
        window.webkit.messageHandlers.selectInlineImage.postMessage({"messageHandler": "selectInlineImage", "cid": cid});
    } else {
        html_editor.getCaretYPosition();
    }
});

html_editor.absorbContactGroupPaste = function (event) {
    const paste = (event.clipboardData || window.clipboardData).getData("text");
    let parsed;

    try {
        parsed = JSON.parse(paste);
    } catch (e) {
        return;
    }

    if (!parsed) {
        return;
    }

    const values = Object.values(parsed);

    if (values.length !== 1) {
        // If the pasted data is contact group, it must have 1 key
        return;
    }

    const [data] = values;

    if (!Array.isArray(data)) {
        return;
    }

    const notStrings = data.some((item) => typeof item !== "string");

    if (notStrings) {
        // If the pasted data is contact group, the data must a string array
        return;
    }

    const selection = window.getSelection();

    if (!selection.rangeCount) {
        return;
    }

    selection.deleteFromDocument();

    const divs = data.map((item) => {
        const div = document.createElement("div");
        div.textContent = item;
        return div;
    });

    const range = selection.getRangeAt(0);

    divs.reverse().forEach((item) => range.insertNode(item));
    event.preventDefault();
}

/// catches pasted images to turn them into data blobs and add as attachments
html_editor.absorbImage = function (event, items, target) {
    for (var m = 0; m < items.length; m++) {
        var file = items[m].getAsFile();
        if (file == undefined || file == null) {
            continue;
        }
        event.preventDefault(); // prevent default only if a file is pasted
        html_editor.getBase64FromFile(file, function (base64) {
            var name = html_editor.createUUID() + "_" + file.name;
            var bits = "data:" + file.type + ";base64," + base64;
            html_editor.insertEmbedImage(`cid:${name}`, bits)

            window.webkit.messageHandlers.addImage.postMessage({ "messageHandler": "addImage", "cid": name, "data": base64 });
        });
    }
};

// Remove color information of pasted data
html_editor.handlePastedData = function (event) {
    // Safari doesn't support regular expression lookahead
    // To remove style has prefix `font-` except `font-style` and `font-weight`
    // Use this workaround
    const item = event.clipboardData
        .getData('text/html')
        .replace(/<meta (.*?)>/g, '')
        .replace(/((\w|-)*?color\s*:.*?)("|;)/g, '$3')
        .replace(/font-style/g, 'elyts-tnof')
        .replace(/font-weight/g, 'thgiew-tnof')
        .replace(new RegExp('font.*?:.*?(;|")', 'g'), '$1')
        .replace(/elyts-tnof/g, 'font-style')
        .replace(/thgiew-tnof/g, 'font-weight')
    if (item == undefined || item.length === 0) { return }
    event.preventDefault();
    const processedData = uploadImageIfPastedDataHasImage(item)

    let selection = window.getSelection()
    if (selection.rangeCount === 0) { return }
    let range = selection.getRangeAt(0);
    range.deleteContents();
    let div = document.createElement('div');
    div.innerHTML = processedData;
    let fragment = document.createDocumentFragment();
    let child;
    while ((child = div.firstChild)) {
        fragment.appendChild(child);
    }
    range.insertNode(fragment);
}

function uploadImageIfPastedDataHasImage(pastedDataText) {
    const parsedDOM = new DOMParser().parseFromString(pastedDataText, "text/html");
    const imageElements = parsedDOM.querySelectorAll('img')
    for (var i = 0; i < imageElements.length; i++) {
        const element = imageElements[i]

        // bits = 'data:image.....'
        const bits = element.src
        const base64 = bits.replace(/data:image\/[a-z]+;base64,/, '').trim();
        const fileType = getFileTypeFromBase64String(bits)
        const cid = html_editor.createUUID()
        const protonCID = `proton-cid:${cid}`
        const name = `${cid}_.${fileType}`

        element.removeAttribute('style')
        element.setAttribute('draggable', 'false')
        element.setAttribute('src-original-pm-cid', protonCID)
        html_editor.cachedCIDs[protonCID] = bits;
        window.webkit.messageHandlers.addImage.postMessage({ "messageHandler": "addImage", "cid": cid, "data": base64 });
    }
    return parsedDOM.body.innerHTML
}

function getFileTypeFromBase64String(base64) {
    const match = base64.match(/data:.*\/(.*);/)
    if (match.length == 2) {
        return match[1]
    } else {
        return ''
    }
}

/// breaks the block quote into two if possible
html_editor.editor.addEventListener("keydown", function (key) {
    quote_breaker.breakQuoteIfNeeded(key);
});

let observer = new ResizeObserver((elements) => {
    let height = elements[0].contentRect.height;
    window.webkit.messageHandlers.heightUpdated.postMessage({ "messageHandler": "heightUpdated", "height": height });
})
observer.observe(document.body)

html_editor.caret = document.createElement('caret'); // something happening here preventing selection of elements
html_editor.getCaretYPosition = function () {
    const range = window.getSelection().getRangeAt(0).cloneRange();
    range.collapse(false)
    const rangeRect = range.getClientRects()[0];
    if (rangeRect) {
        const x = rangeRect.left; // since the caret is only 1px wide, left == right
        const y = rangeRect.top; // top edge of the caret
        window.webkit.messageHandlers.moveCaret.postMessage({ "messageHandler": "moveCaret", "cursorX": x, "cursorY": y });
    }
}

//this is for update protonmail email signature
html_editor.updateSignature = function (html, sanitizeConfig) {
    var signature = document.querySelector('div.protonmail_signature_block');
    if (!signature) {
        return
    }
    var cleanByConfig = DOMPurify.sanitize(html, sanitizeConfig);
    signature.innerHTML = DOMPurify.sanitize(cleanByConfig);
}

// for calls from Swift
html_editor.updateEncodedEmbedImage = function (cid, blobdata) {
    var found = document.querySelectorAll('img[src="' + cid + '"]');
    for (var i = 0; i < found.length; i++) {
        var originalImageData = decodeURIComponent(blobdata);
        html_editor.setImageData(found[i], cid, originalImageData);
    }
}

html_editor.insertEmbedImage = function (cid, base64) {
    let embed = document.createElement('img');
    embed.src = base64;
    embed.setAttribute('draggable', 'false')
    embed.setAttribute('src-original-pm-cid', `${cid}`);
    html_editor.cachedCIDs[cid] = base64;

    const selection = window.getSelection();
    if (selection.rangeCount > 0) {
        const upperBr = document.createElement('br');
        const lowerBr = document.createElement('br');
        const range = selection.getRangeAt(0).cloneRange();
        range.insertNode(upperBr)
        range.insertNode(embed)
        range.insertNode(lowerBr)
        return
    }

    let firstDiv = html_editor.editor.querySelector('div');
    if (firstDiv === null) {
        firstDiv = document.createElement('div');
        firstDiv.innerHTML = "<br> <br>";
        html_editor.editor.appendChild(firstDiv);
    }

    const range = new Range()
    range.setStart(firstDiv, 1);
    range.setEnd(firstDiv, 1);
    range.insertNode(embed);
}

// for calls from JS
html_editor.updateEmbedImage = function (cid, blobdata) {
    var found = document.querySelectorAll('img[src="' + cid + '"]');
    for (var i = 0; i < found.length; i++) {
        html_editor.setImageData(found[i], cid, blobdata);
    }
}

html_editor.hideEmbedImageIn = function(element, cid) {
    var found = element.querySelectorAll('img[src-original-pm-cid="' + cid + '"]');
    for (var i = 0; i < found.length; i++) {
        found[i].setAttribute('src', cid);
    }
}

html_editor.setImageData = function (image, cid, blobdata) {
    image.setAttribute('src-original-pm-cid', cid);
    html_editor.cachedCIDs[cid] = blobdata;
    image.setAttribute('src', blobdata);
    image.class = 'proton-embedded';
}

html_editor.acquireEmbeddedImages = function () {
    var found = document.querySelectorAll('img[src^="blob:null"], img[src^="webkit-fake-url://"]');
    for (var i = 0; i < found.length; i++) {
        html_editor.getBase64FromImageUrl(found[i], function (oldImage, cid, data) {
            html_editor.setImageData(oldImage, "cid:" + cid, data);
            var bits = data.replace(/data:image\/[a-z]+;base64,/, '');
            window.webkit.messageHandlers.addImage.postMessage({ "messageHandler": "addImage", "cid": cid, "data": bits });
        });
    }
}

html_editor.getBase64FromImageUrl = function (oldImage, callback) {
    var img = new Image();
    img.onload = function (e) {
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

html_editor.removeEmbedImage = function (cid) {
    var found = document.querySelectorAll('img[src-original-pm-cid="' + cid + '"]');
    if (found.length != 0) {
        for (var i = 0; i < found.length; i++) {
            found[i].remove();
        }
    } else {
        let prefixToRemove = 'proton-'
        var cidWithoutPrefix = cid;
        if (cid.startsWith(prefixToRemove)) {
            cidWithoutPrefix = cid.substring(prefixToRemove.length);
        }
        var founded = document.querySelectorAll('img[src-original-pm-cid="' + cidWithoutPrefix + '"]');
        for (var i = 0; i < founded.length; i++) {
            founded[i].remove();
        }
    }
    let contentsHeight = html_editor.getContentsHeight();
    window.webkit.messageHandlers.heightUpdated.postMessage({ "messageHandler": "heightUpdated", "height": contentsHeight });
}

html_editor.getContentsHeight = function () {
    var rects = document.body.getBoundingClientRect();
    return rects.height;
}

html_editor.getBase64FromFile = function (file, callback) {
    var reader = new FileReader();
    reader.onloadend = function (e) {
        var binary = '';
        var bytes = new Uint8Array(e.target.result);
        var len = bytes.byteLength;
        for (var i = 0; i < len; i++) {
            binary += String.fromCharCode(bytes[i]);
        }
        var base64 = window.btoa(binary);
        return callback(base64);
    };
    reader.readAsArrayBuffer(file);
}

html_editor.createUUID = function () {
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
html_editor.clearNodeStyling = function (node) {
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

html_editor.removeStyleFromSelection = function () {
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
    for (var i = siblings.length - 1; i >= 0; i--) {
        html_editor.clearNodeStyling(siblings[i]);
    }
}

html_editor.update_font_size = function (size) {
    let pixelSize = size + "px";
    document.documentElement.style.setProperty("font-size", pixelSize);
};

const toMap = function (list) {
    return list.reduce(function (acc, key) {
        acc[key] = true;
        return acc;
    }, {});
};
const LIST_PROTON_ATTR = ['data-src', 'src', 'srcset', 'background', 'poster', 'xlink:href', 'href'];
const MAP_PROTON_ATTR = toMap(LIST_PROTON_ATTR);
const PROTON_ATTR_TAG_WHITELIST = ['a', 'base'];
const MAP_PROTON_ATTR_TAG_WHITELIST = toMap(PROTON_ATTR_TAG_WHITELIST.map(function (tag) { return tag.toUpperCase(); }));
const shouldPrefix = function (tagName, attributeName) {
    return !MAP_PROTON_ATTR_TAG_WHITELIST[tagName] && MAP_PROTON_ATTR[attributeName];
};
const ATTRIBUTES_TO_LOAD = ['url', 'xlink:href', 'src', 'svg', 'background', 'poster'];
const ATTRIBUTES_TO_FIND = ['url', 'xlink:href', 'src', 'srcset', 'svg', 'background', 'poster'];

html_editor.beforeSanitizeElements = function (node) {
    // We only work on elements
    if (node.nodeType !== 1) {
        return node;
    }

    const element = node;

    // Manage styles element
    if (element.tagName === 'STYLE') {
        const escaped = escapeForbiddenStyle(escapeURLinStyle(element.innerHTML || ''));
        element.innerHTML = escaped;
    }

    Array.from(element.attributes).forEach((type) => {
        const item = type.name;

        if (shouldPrefix(element.tagName, item)) {
            var attribute = element.getAttribute(item);
            // Don't update base64 string
            // Mainly for signature case
            if (!attribute.startsWith('data:')) {
                const originalUrl = attribute;
                const replacedUrl = 'proton-' + attribute;
                element.setAttribute(item, replacedUrl || '');
            }
        }

        // Manage element styles tag
        if (item === 'style') {
            const escaped = escapeForbiddenStyle(escapeURLinStyle(element.getAttribute('style') || ''));
            element.setAttribute('style', escaped);
        }
    });

    return element;
};

html_editor.getRemoteImageMatches = function(message) {
    let SELECTOR = ATTRIBUTES_TO_FIND.map((name) => {
        if (name === 'src') {
            return '[src]:not([src^="cid"]):not([src^="data"])';
        }

        // https://stackoverflow.com/questions/23034283/is-it-possible-to-use-htmls-queryselector-to-select-by-xlink-attribute-in-an
        if (name === 'xlink:href') {
            return '[*|href]:not([href])';
        }

        return `[proton-${name}]`;
    }).join(',');

    const imageElements = [...message.querySelectorAll(SELECTOR)];
    const styleElements = [...message.querySelectorAll('[style]')];

    const elementsWithStyleTag = styleElements.reduce(function (acc, elWithStyleTag) {
        const styleTagValue = elWithStyleTag.getAttribute('style');
        const hasSrcAttribute = elWithStyleTag.hasAttribute('src');
        if (styleTagValue && !hasSrcAttribute && styleTagValue.includes('proton-url')) {
            acc.push(elWithStyleTag);
        }
        return acc;
    }, []);

    return {
        matchedElements: [...imageElements, ...styleElements],
        hasRemoteImages: imageElements.length + elementsWithStyleTag.length > 0
    }
};
