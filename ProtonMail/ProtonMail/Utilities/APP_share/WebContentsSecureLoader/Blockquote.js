const BLOCKQUOTE_SELECTOR = {{BLOCKQUOTE_SELECTOR_VALUE}}

const split = (source, match) => {
    const index = source.indexOf(match);
    if (index === -1) {
        return [source, ''];
    }
    return [source.slice(0, index), source.slice(index + match.length)];
};

var searchBlockQuote = (document) => {
    const bodyDocument = document.querySelector('body');
    const parentHTML = bodyDocument.innerHTML || '';
    const parentText = bodyDocument.textContent || '';
    let result = null;

    const testBlockquote = (blockquote) => {
        const blockquoteText = blockquote.textContent || '';
        const [, afterText = ''] = split(parentText, blockquoteText);

        if (!afterText.trim().length) {
            const blockquoteHTML = blockquote.outerHTML || '';
            const [beforeHTML = ''] = split(parentHTML, blockquoteHTML);
            return [beforeHTML, blockquoteHTML];
        }

        return null;
    };

    const searchForContent = (element, text) => {
        const xpathResult = element.ownerDocument?.evaluate(
                                                            `//*[text()='${text}']`,
                                                            element,
                                                            null,
                                                            XPathResult.ORDERED_NODE_ITERATOR_TYPE,
                                                            null
                                                            );
        const result = [];
        let match = null;
        while ((match = xpathResult?.iterateNext())) {
            result.push(match);
        }
        return result;
    };

    // Standard search with a composed query selector
    const blockQuotes = [...document.querySelectorAll(BLOCKQUOTE_SELECTOR)];
    blockQuotes.forEach((blockQuote) => {
        if (result === null) {
            result = testBlockquote(blockQuote);
        }
    });

    // Second search based on text content with xpath
    if (result === null) {
        BLOCKQUOTE_TEXT_SELECTORS.forEach((text) => {
            if (result === null) {
                searchForContent(document, text).forEach((blockquote) => {
                    if (result === null) {
                        result = testBlockquote(blockquote);
                    }
                });
            }
        });
    }

    return result;
}
