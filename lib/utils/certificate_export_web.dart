import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool get canExportCertificate => true;

/// Opens a new browser tab containing a self-contained, styled certificate and
/// triggers the print dialog so the user can print or "Save as PDF".
void exportCertificate({
  required String studentName,
  required String courseTitle,
  required String instructorName,
  required String dateText,
}) {
  final html = _certificateHtml(
    studentName: studentName,
    courseTitle: courseTitle,
    instructorName: instructorName,
    dateText: dateText,
  );
  final win = web.window.open('', '_blank');
  if (win == null) return;
  win.document.open();
  win.document.write(html.toJS);
  win.document.close();
}

String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _certificateHtml({
  required String studentName,
  required String courseTitle,
  required String instructorName,
  required String dateText,
}) {
  return '''
<!doctype html>
<html>
<head>
<meta charset="utf-8" />
<title>Certificate - ${_escape(courseTitle)}</title>
<style>
  * { box-sizing: border-box; }
  body {
    font-family: Georgia, "Times New Roman", serif;
    margin: 0;
    background: #eef0f6;
    color: #1f2340;
  }
  .sheet {
    width: 960px;
    max-width: 92vw;
    margin: 32px auto;
    background: #ffffff;
    padding: 24px;
  }
  .frame {
    border: 3px solid #5b4bdb;
    outline: 1px solid #b9b1f2;
    outline-offset: 6px;
    padding: 56px 64px;
    text-align: center;
  }
  .kicker {
    letter-spacing: 6px;
    text-transform: uppercase;
    font-size: 14px;
    color: #6b6f8c;
    font-family: Arial, sans-serif;
  }
  h1 {
    font-size: 44px;
    margin: 10px 0 6px;
    color: #5b4bdb;
  }
  .sub { font-size: 16px; color: #6b6f8c; margin-bottom: 34px; }
  .name {
    font-size: 40px;
    font-weight: bold;
    margin: 8px 0;
    border-bottom: 2px solid #e2e0f5;
    display: inline-block;
    padding: 0 24px 8px;
  }
  .course { font-size: 24px; margin: 26px 0 6px; }
  .course strong { color: #5b4bdb; }
  .footer {
    display: flex;
    justify-content: space-between;
    margin-top: 56px;
    font-family: Arial, sans-serif;
    font-size: 14px;
    color: #4a4f70;
  }
  .footer .line { border-top: 1.5px solid #9a95c9; padding-top: 6px; width: 240px; }
  .toolbar { text-align: center; margin: 18px; }
  .toolbar button {
    font: 600 15px Arial, sans-serif;
    background: #5b4bdb; color: #fff; border: none;
    padding: 10px 22px; border-radius: 8px; cursor: pointer;
  }
  @media print { .toolbar { display: none; } body { background: #fff; } .sheet { margin: 0; } }
</style>
</head>
<body>
  <div class="toolbar"><button onclick="window.print()">Print / Save as PDF</button></div>
  <div class="sheet">
    <div class="frame">
      <div class="kicker">Certificate of Completion</div>
      <h1>LMS Learning Platform</h1>
      <div class="sub">This certifies that</div>
      <div class="name">${_escape(studentName)}</div>
      <div class="course">has successfully completed<br/><strong>${_escape(courseTitle)}</strong></div>
      <div class="footer">
        <div class="line">Instructor: ${_escape(instructorName)}</div>
        <div class="line">Date: ${_escape(dateText)}</div>
      </div>
    </div>
  </div>
</body>
</html>
''';
}
