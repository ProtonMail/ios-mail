const scaleContentSize = function () {
    function updatePropertyIfStatic(element, propertyName, mode) {
        const currentPropertyValue = element.style.getPropertyValue(propertyName);

        if (!currentPropertyValue) {
            return;
        }

        const originalPropertyName = getOriginalPropertyName(propertyName);

        if (!element.style.getPropertyValue(originalPropertyName)) {
            setInlineStyleProperty(element, originalPropertyName, currentPropertyValue);
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
                        setInlineStyleProperty(element, propertyName, scaledValue + unit + " !important");
                    }).catch(error => {
                        console.error(error);
                    });
            case "remove":
                setInlineStyleProperty(element, propertyName, null);
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

        setInlineStyleProperty(element, propertyName, originalFullValue);
        setInlineStyleProperty(element, originalPropertyName, null);
    }

    applyToAllElements(function (element) {
        restoreOriginalProperty(element, "font-size");
        restoreOriginalProperty(element, "line-height");
    });
}

function setInlineStyleProperty(element, propertyName, newValue) {
    const rawStyle = element.getAttribute("style");
    const keyValueStrings = rawStyle.split(";");

    var newKeyValueStrings = keyValueStrings.filter((keyValueString) => {
        const keyValueStringComponents = keyValueString.split(":");

        if (keyValueStringComponents.length > 0) {
            return keyValueStringComponents[0].trim() != propertyName;
        } else {
            return false;
        }
    });

    if (newValue != null) {
        newKeyValueStrings.push(propertyName + ":" + newValue)
    }

    const newStyleString = newKeyValueStrings.join(";") + ";";
    element.setAttribute("style", newStyleString);
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
