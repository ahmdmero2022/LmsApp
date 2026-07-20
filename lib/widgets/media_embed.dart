// Renders embedded media (video / PDF) inline. On the web this uses an
// `<iframe>`; on other platforms it falls back to a placeholder (users open
// the media in a new tab from the button in the course detail screen).
export 'media_embed_stub.dart'
    if (dart.library.js_interop) 'media_embed_web.dart';
