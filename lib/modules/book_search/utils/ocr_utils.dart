import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRUtils {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  static Future<String> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      return '';
    }
  }

  static Future<void> dispose() async {
    await _textRecognizer.close();
  }

  static String? extractIsbn(String text) {
    // Try to find ISBN-13 or ISBN-10 patterns
    final isbn13Pattern = RegExp(r'\b97[89]\d{10}\b');
    final isbn10Pattern = RegExp(r'\b\d{9}[\dX]\b');
    
    final isbn13Match = isbn13Pattern.firstMatch(text);
    if (isbn13Match != null) {
      return isbn13Match.group(0);
    }
    
    final isbn10Match = isbn10Pattern.firstMatch(text);
    if (isbn10Match != null) {
      return isbn10Match.group(0);
    }
    
    return null;
  }
}


