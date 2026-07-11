enum ControlType {
  text,
  select,
  checkbox,
  radio,
  date,
  number
}

enum ControlComponent {
  prefix,
  postfix,
  preText,
  postText,
  placeholder,
  value,
  checkbox,
  radio
}

// 控件内容缩进方式
enum ControlIndentation {
  rowStart, // 从行起始位置缩进
  valueStart // 从值起始位置缩进
}

// 控件状态
enum ControlState {
  active,
  inactive
}