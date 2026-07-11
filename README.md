# Dart Quill

A web app that uses AngularDart.

## Getting Started

1. Get the dependencies:
```bash
dart pub get
```

2. Launch a development server:
```bash
webdev serve
```

3. In a browser, open [http://localhost:8080](http://localhost:8080)

## Building for Production

```bash
webdev build
```

## File-based styles and Tabler icons

The embedded Snow stylesheet remains available through
`QuillAssets.injectSnowTheme()`. Applications that prefer static assets can
load these package files instead:

```html
<link rel="stylesheet" href="packages/dart_quill/assets/icons/tabler/tabler-icons.css">
<link rel="stylesheet" href="packages/dart_quill/assets/quill.snow.css">
<link rel="stylesheet" href="packages/dart_quill/assets/quill.limitless.css">
```

When the application already loads the Limitless `all.min.css`, do not load
`quill.snow.css`: Limitless already contains its Quill theme rules. Use only
Tabler and the integration layer after `all.min.css`:

```html
<link rel="stylesheet" href="assets/css/ltr/all.min.css">
<link rel="stylesheet" href="packages/dart_quill/assets/icons/tabler/tabler-icons.css">
<link rel="stylesheet" href="packages/dart_quill/assets/quill.limitless.css">
```

Enable Tabler markup when creating the editor:

```dart
final options = ThemeOptions(
  theme: 'snow',
  iconTheme: QuillIconTheme.tabler,
);
```

`QuillIconTheme.svg` remains the default for backward compatibility. The
The `quill.limitless.css` integration layer must be loaded after the global
Limitless stylesheet. Never combine SVG and Tabler icon modes in the same
editor instance.
