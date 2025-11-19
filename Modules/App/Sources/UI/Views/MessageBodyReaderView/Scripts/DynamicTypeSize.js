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

function enableDynamicTypeSize(element) {
    updateStylePreservingFormatting(element, (styleProperties) => {
        styleProperties["-webkit-text-size-adjust"] = "var(--dts-scale-factor) !important";
        styleProperties["line-height"] = "initial !important";
        styleProperties["overflow-wrap"] = "anywhere !important";
        styleProperties["text-wrap-mode"] = "wrap !important";
    });
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
elements.forEach(enableDynamicTypeSize);
