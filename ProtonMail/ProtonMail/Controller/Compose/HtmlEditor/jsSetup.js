
var fullscreenNode = document.getElementById('editor');
var contentNode = document.getElementById('editor');
var quotes = new Quotes(contentNode);

contentNode.addEventListener('keydown', onKeydown);
//contentNode.addEventListener('click', onClick);
//contentNode.addEventListener('input', onChange);
//contentNode.addEventListener('focus', onFocus);
//fullscreenNode.addEventListener('click', onClick);

function onKeydown(e) {
    quotes.breakQuote(e);
}

function onChange() {
    ensureCaretIsVisible();
    window.location.href = "yandexmail://change";
}

function onFocus() {
    window.location.href = "yandexmail://onfocus";
}

function onClick() {
    startEditing(false);
}

function contentNodeFocus(omitOnFocusNotification) {
    if (omitOnFocusNotification) {
        contentNode.removeEventListener('focus', onFocus, false)
    }
    contentNode.focus();
    if (omitOnFocusNotification) {
        contentNode.addEventListener('focus', onFocus, false);
    }
}

function startEditing(omitOnFocusNotification) {
    if (fullscreenNode.style.display != 'none') {
        fullscreenNode.style.display = 'none';

        contentNode.contentEditable = 'true';
        contentNodeFocus(omitOnFocusNotification);
        moveCursorAtStart(contentNode);
    } else {
        contentNodeFocus(omitOnFocusNotification);
    }
}

function moveCursorAtStart(node) {
    var range = document.createRange();
    range.selectNodeContents(node);
    range.setStart(node.firstChild, 0);
    range.setEnd(node.firstChild, 0);

    var selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
}

function ensureCaretIsVisible() {
    const caretOffsetTop = getCaretOffsetTop();

    const caretPaddingTop = window.innerHeight / 6;
    const caretPaddingBottom = Math.min(caretPaddingTop + 22, contentNode.scrollHeight - caretOffsetTop + 10);

    if (caretOffsetTop - caretPaddingTop < window.pageYOffset) {
        window.scrollTo(0, caretOffsetTop - caretPaddingTop);
    } else if (caretOffsetTop + caretPaddingBottom - window.innerHeight > window.pageYOffset) {
        window.scrollTo(0, caretOffsetTop + caretPaddingBottom - window.innerHeight);
    }
}

function getCaretOffsetTop() {
    var y;
    var range = document.getSelection().getRangeAt(0).cloneRange();

    range.collapse(false);
    var clientRects = range.getClientRects();
    if (clientRects.length > 0) {
        y = clientRects[0].top;
    }

    // Fall back to inserting a temporary element
    if (!y) {
        var span = document.createElement("span");
        // Ensure span has dimensions and position by adding a zero-width space character
        span.appendChild(document.createTextNode("\u200b"));
        range.insertNode(span);
        y = span.getClientRects()[0].top;

        var spanParent = span.parentNode;
        spanParent.removeChild(span);
        // Glue any broken text nodes back together
        spanParent.normalize();
    }

    return y + window.pageYOffset;
}
