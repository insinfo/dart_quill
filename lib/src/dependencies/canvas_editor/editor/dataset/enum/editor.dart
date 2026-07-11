enum EditorComponent {
  component,
  menu,
  main,
  footer,
  contextmenu,
  popup,
  catalog,
  comment
}

enum EditorContext {
  page,
  table
}

enum EditorMode {
  edit, // 编辑模式（文档可编辑、辅助元素均存在）
  clean, // 清洁模式（隐藏辅助元素）
  readonly, // 只读模式（文档不可编辑）
  graffiti, // 涂鸦模式（文档只读，允许通过鼠标绘制线条）
  form, // 表单模式（仅控件内可编辑）
  print, // 打印模式（文档不可编辑、隐藏辅助元素、选区、未书写控件及边框）
  design // 设计模式（不可删除、只读等配置不控制）
}

enum EditorZone {
  header,
  main,
  footer
}

enum PageMode {
  paging,
  continuity
}

enum PaperDirection {
  vertical,
  horizontal
}

enum WordBreak {
  breakAll,
  breakWord
}

enum RenderMode {
  speed,
  compatibility
}