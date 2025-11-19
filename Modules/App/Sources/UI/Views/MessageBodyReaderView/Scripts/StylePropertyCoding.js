// Copyright (c) 2025 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

/*
 This function facilitates working with the raw value of an element's style attribute.

 Our dark mode support relies on selectors based on verbatim styles, which should not be modified after the dark mode CSS is created by the SDK.

 When element.style.setProperty is used, the browser performs certain tweaks, such as replacing color hex codes with rgba() calls, breaking the aforementioned principle.
 */
function updateStylePreservingFormatting(element, stylePropertiesTransformer) {
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

    const currentStyle = element.getAttribute('style');
    const styleProperties = decodeStyleProperties(currentStyle ?? '');
    stylePropertiesTransformer(styleProperties);
    const updatedStyle = encodeStyleProperties(styleProperties);
    element.setAttribute("style", updatedStyle);
}
