const elements = document.querySelectorAll(`[style*="font-size"][style*="line-height"]`);

for (const element of elements) {
    const currentStyle = element.getAttribute('style');

    window.webkit.messageHandlers.scaleStyle.postMessage(currentStyle)
        .then(updatedStyle => {
            if (!updatedStyle) {
                return;
            }

            element.setAttribute("style", updatedStyle);
        }).catch(error => {
            console.log(error);
        });
}
