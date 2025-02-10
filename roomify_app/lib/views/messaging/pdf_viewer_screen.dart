import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';

class PDFViewerScreen extends StatelessWidget {
  final File file;

  const PDFViewerScreen({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.path.split('/').last),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () async {
              await Share.shareXFiles([XFile(file.path)]);
            },
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () async {
              try {
                // Copy file to downloads directory
                final downloadDir = Directory('/storage/emulated/0/Download');
                if (!await downloadDir.exists()) {
                  await downloadDir.create(recursive: true);
                }

                final savedFile = File('${downloadDir.path}/${file.path.split('/').last}');
                await file.copy(savedFile.path);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('PDF saved to Downloads')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving PDF: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: PDFView(
        filePath: file.path,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        defaultPage: 0,
        fitPolicy: FitPolicy.BOTH,
        preventLinkNavigation: false,
        onRender: (_pages) {
          // PDF is rendered
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading PDF: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onPageError: (page, error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading page $page: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }
}
