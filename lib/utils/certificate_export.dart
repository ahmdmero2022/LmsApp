// Opens a clean, printable certificate in a new browser tab (Save as PDF via
// the browser print dialog). On non-web platforms this is a no-op — the
// in-app certificate view is still shown.
export 'certificate_export_stub.dart'
    if (dart.library.js_interop) 'certificate_export_web.dart';
