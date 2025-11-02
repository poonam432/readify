import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/book_search_bloc.dart';
import '../blocs/book_search_event.dart';
import '../enums/search_mode.dart';

class ScannerPage extends StatefulWidget {
  final SearchMode searchMode;

  const ScannerPage({
    super.key,
    required this.searchMode,
  });

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture barcodeCapture) {
    final barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final code = barcode.rawValue;

    if (code == null) return;

    // Extract ISBN from barcode
    String? isbn;
    if (widget.searchMode == SearchMode.barcode) {
      // Barcode typically contains ISBN
      isbn = code;
    } else if (widget.searchMode == SearchMode.qrCode) {
      // QR code might contain ISBN or book title
      // Try to extract ISBN from the QR code data
      if (code.contains('ISBN') || code.length >= 10) {
        // Try to extract ISBN
        final regex = RegExp(r'\b\d{10,13}\b');
        final match = regex.firstMatch(code);
        if (match != null) {
          isbn = match.group(0);
        } else {
          // Use the QR code data as search query
          context.read<BookSearchBloc>().add(SearchBooksEvent(code));
          Navigator.of(context).pop();
          return;
        }
      } else {
        // Use QR code data as search query
        context.read<BookSearchBloc>().add(SearchBooksEvent(code));
        Navigator.of(context).pop();
        return;
      }
    }

    if (isbn != null && isbn.isNotEmpty) {
      context.read<BookSearchBloc>().add(SearchByIsbnEvent(isbn));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.searchMode == SearchMode.barcode
              ? 'Scan Barcode'
              : 'Scan QR Code',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Position the ${widget.searchMode == SearchMode.barcode ? 'barcode' : 'QR code'} within the frame',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

