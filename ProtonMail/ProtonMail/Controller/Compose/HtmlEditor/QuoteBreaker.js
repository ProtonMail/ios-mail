var quote_breaker = {};

quote_breaker.init = function() {};
quote_breaker.node = document.getElementById('editor');;
quote_breaker.extractTagsRegExp = new RegExp("<(?:\"[^\"]*\"['\"]*|'[^']*'['\"]*|[^'\">])+>", 'gi');

quote_breaker.indexOfFirst = function(array, predicate) {
    for (var index = 0, length = array.length; index < length; ++index) {
        if (predicate(array[index])) {
            return index;
        }
    }
    return -1;
};

quote_breaker.breakableTags = ['div', 'span', 'strong', 'em', 'b', 'i', 'p', 'blockquote', 'a', 'u', 'ol', 'li', 'ul'];

quote_breaker.getPreCaretHtml = function() {
    var doc = this.node.ownerDocument || this.node.document;
    var view = doc.defaultView || doc.parentWindow;
    var innerHtml;
    var selection = view.getSelection();
    if (selection.rangeCount > 0) {
        var range = view.getSelection().getRangeAt(0);
        var coursor = document.createElement('coursor');
        range.insertNode(coursor);
        innerHtml = this.node.innerHTML;
        innerHtml = innerHtml.substring(0, innerHtml.indexOf('<coursor>'));
    }
    return innerHtml;
};

quote_breaker.getTagHtml = function(element) {
    this.extractTagsRegExp.lastIndex = 0;
    return element.outerHTML.match(this.extractTagsRegExp)[0];
};

quote_breaker.getOpenTags = function() {
    var coursor = this.node.querySelector('coursor');
    var parents = [];
    var parent = coursor.parentNode;
    var parentNode = coursor.parentNode;
    var index = -1;

    while (parent !== this.node) {
        parents.push({
            name: parent.tagName.toLowerCase(),
            html: this.getTagHtml(parent)
        });
        parent = parent.parentNode;
    }

    coursor.parentNode.removeChild(coursor);

    for (var i = parents.length - 1; i >= 0; i--) {
        if (parents[i].name === 'blockquote') {
            index = i;
        };
    };

    return [parents.slice(0, index + 1), parentNode];
};

quote_breaker.canBreakQuote = function(tags) {
    var breakableTags = this.breakableTags;
    var index = this.indexOfFirst(tags, function(tag) {
        return breakableTags.indexOf(tag.name) === -1;
    });
    return index === -1;
};

quote_breaker.getQuoteBreakerHtml = function(openTags) {
    var html = [];
    var i;
    var tag;

    for (i = 0; i < openTags.length; i++) {
        tag = openTags[i];
        html.push('</' + tag.name + '>');
    }
    html.push('<coursor></coursor>');
    html.push('<br />');

    for (i = openTags.length - 1; i >= 0; i--) {
        tag = openTags[i];
        html.push(tag.html);
    }

    return html.join('');
};

quote_breaker.insertCaretAtQuoteBreak = function() {
    var range = document.createRange();
    var selection = window.getSelection();
    var coursor = this.node.querySelector('coursor');

    range.setStart(coursor, 0);
    range.collapse(true);
    selection.removeAllRanges();
    selection.addRange(range);

    coursor.parentNode.removeChild(coursor);
};

quote_breaker.clearEmptyQuotes = function() {
    var quotes = this.node.querySelectorAll('blockquote');
    var quote;
    var length = quotes.length;

    while (length-- > 0) {
        quote = quotes[length];
        if (!quote.innerText || this.brOrWhitespaceOnly(quote)) {
            quote.parentNode.removeChild(quote);
        }
    }
};

quote_breaker.clearEmptyChildElements = function() {
    var elements = this.node.querySelectorAll('blockquote');
    var element;
    var children;
    var firstChild;

    var removeFirstChildIfEmpty = function(element) {
        children = element.childNodes;
        if (children.length) {
            firstChild = children[0];
            if (firstChild.nodeType === 1 && !firstChild.innerText) {
                firstChild.parentNode.removeChild(firstChild);
            }
            removeFirstChildIfEmpty(firstChild);
        }
    };

    for (var i = 0; i < elements.length; i++) {
        element = elements[i];
        removeFirstChildIfEmpty(element);
    }
};

quote_breaker.brOrWhitespaceOnly = function(node) {
    var brOnly = true;
    var childNodes = node.childNodes;
    var isBr;
    var isWhitespace;
    var childNode;
    for (var i = 0; i < childNodes.length; i++) {
        childNode = childNodes[i];
        isBr = childNode.tagName === 'BR';
        isWhitespace = childNode.nodeType === 3 && /^\s+$/.test(childNode.nodeValue);
        if (!isBr && !isWhitespace) {
            brOnly = false;
            break;
        }
    }
    return brOnly;
};

quote_breaker.trimLeadingBr = function(html) {
    return html.replace(/^(\s*<br\s*\/?>){1}/, '');
};

quote_breaker.breakQuoteIfNeeded = function(e) {
    if (e.keyCode !== 13) {
        return;
    };

    var preCaretHtml = this.getPreCaretHtml();
    var ot = this.getOpenTags();
    var openTags = ot[0];
    var parentNode = ot[1];

    if (this.indexOfFirst(openTags, function(tag) { return tag.name === 'blockquote'; }) === -1) {
        return;
    }

    if (parentNode.tagName.toLowerCase() === 'a') {
        var range = document.createRange();
        var selection = window.getSelection();

        range.setStartAfter(parentNode);
        range.collapse(true);
        selection.removeAllRanges();
        selection.addRange(range);

        preCaretHtml = this.getPreCaretHtml();
        openTags = this.getOpenTags()[0];
    }

    if (this.canBreakQuote(openTags) == false) {
        return;
    }
    e.preventDefault();

    var position = preCaretHtml.length;
    var breakerHtml = this.getQuoteBreakerHtml(openTags);

    var innerHtml = this.node.innerHTML;
    var postCaretHtml = innerHtml.slice(position);
    postCaretHtml = this.trimLeadingBr(postCaretHtml);
    innerHtml = preCaretHtml + breakerHtml + postCaretHtml;
    this.node.innerHTML = innerHtml;

    this.clearEmptyQuotes();
    this.clearEmptyChildElements();
    this.insertCaretAtQuoteBreak();
};
