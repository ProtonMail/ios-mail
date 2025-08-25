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

function initUpsellOverride(wrapperClass) {
    function replaceUpsellHandler() {
        const upsellButton = document.querySelector(`.${wrapperClass} .button-promotion`);

        if (upsellButton) {
            const newButton = upsellButton.cloneNode(true);

            newButton.addEventListener('click', function (e) {
                e.preventDefault();
                e.stopPropagation();
                window.webkit.messageHandlers.upsell.postMessage(wrapperClass);
            });

            upsellButton.parentNode.replaceChild(newButton, upsellButton);
            return true;
        } else {
            return false;
        }
    }

    // Try to replace immediately
    if (!replaceUpsellHandler()) {
        // If not found, wait for DOM to load the component
        const observer = new MutationObserver(() => {
            if (replaceUpsellHandler()) {
                observer.disconnect();
            }
        });

        observer.observe(document.body, { childList: true, subtree: true });

        // Stop trying after 5 seconds
        setTimeout(() => observer.disconnect(), 5000);
    }
}

initUpsellOverride('folders-action');
initUpsellOverride('labels-action');
