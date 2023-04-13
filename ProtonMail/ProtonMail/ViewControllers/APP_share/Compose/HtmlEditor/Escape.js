"use strict";
/*
 * This is valid
 * - background:&#117;r&#108;(
 * - background:&#117;r&#108;(
 * - background:url&lpar;
 * - etc.
 */
var CSS_URL = '((url|image-set)(\\(|&(#40|#x00028|lpar);))';
var REGEXP_URL_ATTR = new RegExp(CSS_URL, 'gi');
var REGEXP_HEIGHT_PERCENTAGE = /((?:min-|max-|line-)?height)\s*:\s*([\d.,]+%)/gi;
var REGEXP_POSITION_ABSOLUTE = /position\s*:\s*absolute/gi;
var REGEXP_MEDIA_DARK_STYLE = /\(\s*prefers-color-scheme\s*:\s*dark\s*\)/gi;

var escape = function (string) {
    var UNESCAPE_HTML_REGEX = /[&<>"']/g;
    var HTML_ESCAPES = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;',
    };
    return string.replace(UNESCAPE_HTML_REGEX, HTML_ESCAPES);
};

var unescape = function (string) {
    var ESCAPED_HTML_REGEX = /&(?:amp|lt|gt|quot|#39);/g;
    var HTML_UNESCAPES = {
        '&amp;': '&',
        '&lt;': '<',
        '&gt;': '>',
        '&quot;': '"',
        '&#39;': "'",
    };
    return string.replace(ESCAPED_HTML_REGEX, HTML_UNESCAPES);
};

/**
 * Unescape a string in hex or octal encoding.
 * See https://www.w3.org/International/questions/qa-escapes#css_other for all possible cases.
 */
var unescapeCSSEncoding = function (str) {
    // Regexp declared inside the function to reset its state (because of the global flag).
    // cf https://stackoverflow.com/questions/1520800/why-does-a-regexp-with-global-flag-give-wrong-results
    var UNESCAPE_CSS_ESCAPES_REGEX = /\\([0-9A-Fa-f]{1,6}) ?/g;
    var UNESCAPE_HTML_DEC_REGEX = /&#(\d+)(;|(?=[^\d;]))/g;
    var UNESCAPE_HTML_HEX_REGEX = /&#x([0-9A-Fa-f]+)(;|(?=[^\d;]))/g;
    var OTHER_ESC = /\\(.)/g;
    var handleEscape = function (radix) {
        return function (ignored, val) {
            try {
                return String.fromCodePoint(Number.parseInt(val, radix));
            }
            catch (_a) {
                // Unescape regexps have some limitations, for those rare situations, fromCodePoint can throw
                // One real found is: `font-family:\2018Calibri`
                return '';
            }
        };
    };
    /*
     * basic unescaped named sequences: &amp; etcetera, lodash does not support a lot, but that is not a problem for our case.
     * Actually handling all escaped sequences would mean keeping track of a very large and ever growing amount of named sequences
     */
    var namedUnescaped = (0, unescape)(str);
    // lodash doesn't unescape &#160; or &#xA0; sequences, we have to do this manually:
    var decUnescaped = namedUnescaped.replace(UNESCAPE_HTML_DEC_REGEX, handleEscape(10));
    var hexUnescaped = decUnescaped.replace(UNESCAPE_HTML_HEX_REGEX, handleEscape(16));
    // unescape css backslash sequences
    var strUnescapedHex = hexUnescaped.replace(UNESCAPE_CSS_ESCAPES_REGEX, handleEscape(16));
    return strUnescapedHex.replace(OTHER_ESC, function (_, char) { return char; });
};

/**
 * Input can be escaped multiple times to escape replacement while still works
 * Best solution I found is to escape recursively
 * This is done 5 times maximum. If there are too much escape, we consider the string
 * "invalid" and we prefer to return an empty string
 * @argument str style to unescape
 * @augments stop extra security to prevent infinite loop
 */
var recurringUnescapeCSSEncoding = function (str, stop) {
    if (stop === void 0) { stop = 5; }
    var escaped = (0, unescapeCSSEncoding)(str);
    if (escaped === str) {
        return escaped;
    }
    else if (stop === 0) {
        return '';
    }
    else {
        return (0, recurringUnescapeCSSEncoding)(escaped, stop - 1);
    }
};

/**
 * Escape some WTF from the CSSParser, cf spec files
 * @param  {String} style
 * @return {String}
 */
var escapeURLinStyle = function (style) {
    // handle the case where the value is html encoded, e.g.:
    // background:&#117;rl(&quot;https://i.imgur.com/WScAnHr.jpg&quot;)
    var unescapedEncoding = (0, recurringUnescapeCSSEncoding)(style);
    var escapeFlag = unescapedEncoding !== style;
    var escapedStyle = unescapedEncoding.replace(/\\r/g, 'r').replace(REGEXP_URL_ATTR, 'proton-$2(');
    if (escapedStyle === unescapedEncoding) {
        // nothing escaped: just return input
        return style;
    }
    return escapeFlag ? (0, escape)(escapedStyle) : escapedStyle;
};

var escapeForbiddenStyle = function (style) {
    var parsedStyle = style
        .replace(REGEXP_POSITION_ABSOLUTE, 'position: relative')
        .replace(REGEXP_HEIGHT_PERCENTAGE, function (rule, prop) {
            // Replace nothing in this case.
            if (['line-height', 'max-height'].includes(prop)) {
                return rule;
            }
            return "".concat(prop, ": unset");
        })
        // "never" is not a valid value, it's meant to be invalid and break the media query
        .replace(REGEXP_MEDIA_DARK_STYLE, '(prefers-color-scheme: never)');
    return parsedStyle;
};

var HTML_ENTITIES_TO_REMOVE_CHAR_CODES = [
    9,
    10,
    173,
    8203, // Zero width space : &ZeroWidthSpace; - &NegativeVeryThinSpace; - &NegativeThinSpace; - &NegativeMediumSpace; - &NegativeThickSpace; - &#x0200B; - &#8203;
];
/**
 * Remove completely some HTML entities from a string
 * @param {String} string
 * @return {String}
 */
var unescapeFromString = function (string) {
    var toRemove = HTML_ENTITIES_TO_REMOVE_CHAR_CODES.map(function (charCode) { return String.fromCharCode(charCode); });
    var regex = new RegExp(toRemove.join('|'), 'g');
    return string.replace(regex, '');
};

