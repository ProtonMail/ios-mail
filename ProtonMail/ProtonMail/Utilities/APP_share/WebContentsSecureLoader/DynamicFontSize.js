const scaleContentSize = function () {
    function updatePropertyIfStatic(element, propertyName, mode) {
        const currentPropertyValue = element.style.getPropertyValue(propertyName);

        if (!currentPropertyValue) {
            return;
        }

        const originalPropertyName = getOriginalPropertyName(propertyName);

        if (!element.style.getPropertyValue(originalPropertyName)) {
            element.style.setProperty(originalPropertyName, currentPropertyValue);
        }

        const originalFullValue = element.style.getPropertyValue(originalPropertyName);
        const originalNumericValue = parseFloat(originalFullValue);
        const unit = originalFullValue.match(/[a-z%]+/)?.[0];
        const absoluteUnits = ["cm", "mm", "Q", "in", "pc", "pt", "px"];

        if (!absoluteUnits.includes(unit) && originalFullValue != "0") {
            return;
        }

        switch (mode) {
            case "scale":
                window.webkit.messageHandlers.scaledValue.postMessage(originalNumericValue)
                    .then(scaledValue => {
                        element.style.setProperty(propertyName, scaledValue + unit, "important");
                    }).catch(error => {
                        console.error(error);
                    });
            case "remove":
                element.style.removeProperty(propertyName);
        }
    }

    applyToAllElements(function (element) {
        updatePropertyIfStatic(element, "font-size", "scale");
        updatePropertyIfStatic(element, "line-height", "remove");
    });
}

const resetContentSize = function () {
    function restoreOriginalProperty(element, propertyName) {
        const originalPropertyName = getOriginalPropertyName(propertyName);
        const originalFullValue = element.style.getPropertyValue(originalPropertyName);

        if (!originalFullValue) {
            return;
        }

        element.style.setProperty(propertyName, originalFullValue);
        element.style.removeProperty(originalPropertyName);
    }

    applyToAllElements(function (element) {
        restoreOriginalProperty(element, "font-size");
        restoreOriginalProperty(element, "line-height");
    });
}

function getOriginalPropertyName(propertyName) {
    return originalPropertyName = "--original-" + propertyName;
}

function applyToAllElements(block) {
    const treeWalker = document.createTreeWalker(document.body, NodeFilter.SHOW_ELEMENT, null, false);

    while (treeWalker.nextNode()) {
        block(treeWalker.currentNode);
    }
}
