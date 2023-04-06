"use strict";

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

var beforeSanitizeElements = function (node) {
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
