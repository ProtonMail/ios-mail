var Quotes = (function() {
    /**
     * Компонент, работающий с HTML-цитатами в композе
     * @param {HTMLElement} node
     * @constructor
     */
    var QuotesHtml = function(node) {
        this.node = node;
        this.extractTagsRegExp = new RegExp("<(?:\"[^\"]*\"['\"]*|'[^']*'['\"]*|[^'\">])+>", 'gi');
    };

    var prototype = QuotesHtml.prototype;

    prototype.findLastIndex = function(array, predicate) {
        for (var i = array.length - 1; i >= 0; i--) {
            if (predicate(array[i])) {
                return i;
            }
        }
        return -1;
    };

    prototype.findIndex = function(array, predicate) {
        for (var index = 0, length = array.length; index < length; ++index) {
            if (predicate(array[index])) {
                return index;
            }
        }
        return -1;
    };

    /**
     * Тэги, внутри которых можно разрывать цитату
     * @type {string[]}
     */
    prototype.allowedTags = ['div', 'span', 'strong', 'em', 'b', 'i', 'p', 'blockquote', 'a', 'u', 'ol', 'li', 'ul'];

    /**
     * Получает строку с html до курсора
     * @returns {string}
     */
    prototype.getPreCaretHtml = function() {
        var doc = this.node.ownerDocument || this.node.document;
        var view = doc.defaultView || doc.parentWindow;
        var innerHtml;
        var selection = view.getSelection();
        if (selection.rangeCount > 0) {
            var range = view.getSelection().getRangeAt(0);
            // Хитрый способ: на позицию курсора вставляем html-элемент, которого нет в теле письма (например, <caret/>).
            // Потом получаем часть innerHtml до этого элемента.
            var caret = document.createElement('caret');
            range.insertNode(caret);
            innerHtml = this.node.innerHTML;
            innerHtml = innerHtml.substring(0, innerHtml.indexOf('<caret>'));
        }
        return innerHtml;
    };

    /**
     * Получает html-код тэга
     * @param {HTMLElement} element
     * @returns {string}
     */
    prototype.getTagHtml = function(element) {
        // TODO Найти способ получше
        this.extractTagsRegExp.lastIndex = 0;
        return element.outerHTML.match(this.extractTagsRegExp)[0];
    };

    /**
     * Возвращает все открытые тэги
     * @returns {Array}
     */
    prototype.getOpenTags = function() {
        var caret = this.node.querySelector('caret');
        var parents = [];
        var parent = caret.parentNode;
        var parentNode = caret.parentNode;

        // Составим список родительских тэгов до корневого элемента
        while (parent !== this.node) {
            parents.push({
                name: parent.tagName.toLowerCase(),
                html: this.getTagHtml(parent)
            });
            parent = parent.parentNode;
        }

        // Не забудем убрать элемент caret
        caret.parentNode.removeChild(caret);

        // Найдём верхний тэг blockquote и обрежем по нему массив тэгов: открытые тэги выше blockquote не важны
        var index = this.findLastIndex(parents, function(tag) {
            return tag.name === 'blockquote';
        });
        return [parents.slice(0, index + 1), parentNode];
    };

    /**
     * Определяет, нужно ли разрывать цитату
     * @param {Array} tags Список открытых тэгов внутри цитаты
     * @returns {boolean}
     */
    prototype.canBreakQuote = function(tags) {
        // Элементы, которые можно попытаться закрыть
        var allowedTags = this.allowedTags;
        // Поищем тэг, которого нет в списке разрешённых
        var index = this.findIndex(tags, function(tag) {
            // Если среди этих тэгов есть сложные тэги (не из списка tagNames), не будем рвать цитату
            return allowedTags.indexOf(tag.name) === -1;
        });
        return index === -1;
    };

    /**
     * Возвращает строку html, разрывающую цитату
     * @param {Array} openTags Список открытых тэгов
     * @returns {string}
     */
    prototype.getQuoteBreakerHtml = function(openTags) {
        var html = [];
        var i;
        var tag;

        // Закрываем тэги в обратном порядке
        for (i = 0; i < openTags.length; i++) {
            tag = openTags[i];
            html.push('</' + tag.name + '>');
        }
        html.push('<caret></caret>');
        html.push('<br />');

        // Открываем тэги
        for (i = openTags.length - 1; i >= 0; i--) {
            tag = openTags[i];
            html.push(tag.html);
        }

        return html.join('');
    };

    /**
     * Помещает курсор туда, где разорвана цитата
     */
    prototype.insertCaretAtQuoteBreak = function() {
        var range = document.createRange();
        var selection = window.getSelection();
        // Поищем элемент caret, который должен был добавиться в месте разрыва цитаты
        var caret = this.node.querySelector('caret');

        range.setStart(caret, 0);
        range.collapse(true);
        selection.removeAllRanges();
        selection.addRange(range);

        caret.parentNode.removeChild(caret);
    };

    /**
     * Убирает пустые элементы <blockquote>, которые иногда образуются после разрыва цитаты
     */
    prototype.clearEmptyCites = function() {
        var cites = this.node.querySelectorAll('blockquote');
        var cite;
        var length = cites.length;

        while (length-- > 0) {
            cite = cites[length];
            // Если нет внутреннего текста или только пробелы или только тэги br
            if (!cite.innerText || this.brOrWhitespaceOnly(cite)) {
                cite.parentNode.removeChild(cite);
            }
        }
    };

    /**
     * Убирает пустые child'ы элементов blockquote, образовавшиеся после разрыва цитат
     */
    prototype.clearEmptyChildElements = function() {
        var elements = this.node.querySelectorAll('blockquote');
        var element;
        var children;
        var firstChild;

        var removeFirstChildIfEmpty = function(element) {
            children = element.childNodes;
            if (children.length) {
                firstChild = children[0];
                if (firstChild.nodeType === 1 && !firstChild.innerText) {
                    firstChild.parentNode.removeChild(firstChild);
                }
                removeFirstChildIfEmpty(firstChild);
            }
        };

        for (var i = 0; i < elements.length; i++) {
            element = elements[i];
            removeFirstChildIfEmpty(element);
        }
    };

    /**
     * Проверяет, что внутри тэга только тэги br
     * @param {HTMLElement} node
     * @returns {boolean}
     */
    prototype.brOrWhitespaceOnly = function(node) {
        var brOnly = true;
        var childNodes = node.childNodes;
        var isBr;
        var isWhitespace;
        var childNode;
        for (var i = 0; i < childNodes.length; i++) {
            childNode = childNodes[i];
            isBr = childNode.tagName === 'BR';
            isWhitespace = childNode.nodeType === 3 && /^\s+$/.test(childNode.nodeValue);
            if (!isBr && !isWhitespace) {
                brOnly = false;
                break;
            }
        }
        return brOnly;
    };

    /**
     * Если в начале строки два br или больше, убирает один
     * @param {string} html
     * @returns {string}
     */
    prototype.trimLeadingBr = function(html) {
        return html.replace(/^(\s*<br\s*\/?>){1}/, '');
    };

    /**
     * Разрывает цитату
     * @param {Event} e
     */
    prototype.breakQuote = function(e) {
        // Только при нажатии на enter внутри цитаты
        if (e.keyCode === 13) {
            // Получим html внутри основного элемента до курсора
            var preCaretHtml = this.getPreCaretHtml();
            var ot = this.getOpenTags();
            var openTags = ot[0]; var parentNode = ot[1];

            // Если есть открытые тэги blockquote, значит, мы внутри цитаты.
            // Можно определять расположение внутри цитаты по target события,
            // но для этого нужно каждой цитате задавать атрибут contenteditable=true
            // и оборачивать её в контейнер с contenteditable=false
            if (this.findIndex(openTags, function(tag) { return tag.name === 'blockquote'; }) === -1) {
                return;
            }

            if (parentNode.tagName.toLowerCase() === 'a') {
                var range = document.createRange();
                var selection = window.getSelection();

                range.setStartAfter(parentNode);
                range.collapse(true);
                selection.removeAllRanges();
                selection.addRange(range);

                preCaretHtml = this.getPreCaretHtml();
                openTags = this.getOpenTags()[0];
            }

            // Проверим, можно ли разрывать цитату (нет ли сложных элементов типа таблиц)
            if (this.canBreakQuote(openTags)) {
                e.preventDefault();

                // Позиция курсора. Здесь будем закрывать тэги.
                var position = preCaretHtml.length;

                // На позицию курсора в html-строку вставим локальные закрывающие тэги
                // И строку вида </blockquote><blockquote>, по количеству вложенных цитат на позиции курсора
                var breakerHtml = this.getQuoteBreakerHtml(openTags);

                // Вставим полученную html-строку как innerHtml в основной элемент
                var innerHtml = this.node.innerHTML;
                var postCaretHtml = innerHtml.slice(position);
                postCaretHtml = this.trimLeadingBr(postCaretHtml);
                innerHtml = preCaretHtml + breakerHtml + postCaretHtml;
                this.node.innerHTML = innerHtml;

                // Уборочка
                this.clearEmptyCites();
                this.clearEmptyChildElements();

                this.insertCaretAtQuoteBreak();
            }
        }
    };

    return QuotesHtml;
})();
