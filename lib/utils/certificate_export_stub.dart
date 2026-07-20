/// Non-web fallback: printing/PDF export is only available on the web app.
bool get canExportCertificate => false;

void exportCertificate({
  required String studentName,
  required String courseTitle,
  required String instructorName,
  required String dateText,
}) {
  // No-op outside the web.
}
