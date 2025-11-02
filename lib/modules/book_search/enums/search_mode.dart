enum SearchMode {
  text,
  qrCode,
  barcode,
  ocr,
}

extension SearchModeExtension on SearchMode {
  String get label {
    switch (this) {
      case SearchMode.text:
        return 'Text Search';
      case SearchMode.qrCode:
        return 'QR Code';
      case SearchMode.barcode:
        return 'Barcode';
      case SearchMode.ocr:
        return 'OCR';
    }
  }
}


