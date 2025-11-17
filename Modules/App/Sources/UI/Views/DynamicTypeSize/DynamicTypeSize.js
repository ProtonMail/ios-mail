function enableDynamicTypeSize(element) {
    const currentStyle = element.getAttribute('style');
    const styleProperties = decodeStyleProperties(currentStyle ?? '');

    styleProperties["-webkit-text-size-adjust"] = "var(--dts-scale-factor) !important";
    styleProperties["line-height"] = "initial !important";
    styleProperties["overflow-wrap"] = "anywhere !important";
    styleProperties["text-wrap-mode"] = "wrap !important";

    const updatedStyle = encodeStyleProperties(styleProperties);
    element.setAttribute("style", updatedStyle); // do not use element.style.setProperty because it will break dark mode
}

function decodeStyleProperties(styleString) {
    const keyValueStrings = styleString.split(";");

    return keyValueStrings.reduce((styleObject, keyValueString) => {
        const keyValueStringComponents = keyValueString.split(":");

        if (keyValueStringComponents.length >= 2) {
            const key = keyValueStringComponents[0].trim();
            const value = keyValueStringComponents[1].trim();
            styleObject[key] = value;
        }

        return styleObject;
    }, {});
}

function encodeStyleProperties(styleProperties) {
    return Object.entries(styleProperties).map(([key, value]) => `${key}: ${value}`).join(";");
}

function findUniqueElementsContainingNonEmptyTextNodes() {
    const elements = new Set();

    const filter = {
        acceptNode: function (element) {
            const textContent = element.textContent || '';

            if (textContent.trim().length === 0) {
                return NodeFilter.FILTER_SKIP;
            } else {
                return NodeFilter.FILTER_ACCEPT;
            }
        }
    };

    const treeWalker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, filter);

    while (treeWalker.nextNode()) {
        elements.add(treeWalker.currentNode.parentNode);
    }

    return elements;
}

const elements = findUniqueElementsContainingNonEmptyTextNodes();

elements.forEach(element => {
    enableDynamicTypeSize(element);
});
