// O Quill já está carregado neste ponto (este script vem depois do quill.js)
// Registramos o blot IMEDIATAMENTE para evitar race condition no modo release
// onde o Dart pode tentar carregar um delta contendo headerImage antes do DOMContentLoaded
(function () {
    if (!window.Quill) {
        console.error('Quill não está disponível! Verifique a ordem dos scripts.');
        return;
    }

    const BlockEmbed = Quill.import('blots/block/embed');

    // Blot customizado para imagem de cabeçalho (não editável, não removível)
    class HeaderImageBlot extends BlockEmbed {
        static create(value) {
            const node = document.createElement('img');
            node.setAttribute('src', value);
            node.setAttribute('contenteditable', 'false');
            node.style.display = 'block';
            node.style.height = '60px';
            node.className = this.className;
            return node;
        }

        static value(domNode) {
            return domNode.getAttribute('src');
        }

        // Ignora formatação para "travar" o blot
        format(name, value) { }

        // Ignora exclusão para "travar" o blot
        deleteAt(index, length) { super.deleteAt(index, length); }
    }

    HeaderImageBlot.blotName = 'headerImage';
    HeaderImageBlot.tagName = 'img';
    HeaderImageBlot.className = 'ql-header-image';

    Quill.register(HeaderImageBlot);
})();