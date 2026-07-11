if (window.Quill && window.QuillTableBetter) {
    // 1. REGISTRA OS BLOTS (formatos: table-cell, table-row, etc.)
    // Esta é a linha que estava faltando.
    window.QuillTableBetter.register();
    // 2. REGISTRA O MÓDULO (UI, menus, clipboard matchers, etc.)
    Quill.register({ 'modules/table-better': QuillTableBetter }, true);
}