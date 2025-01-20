// import 'package:advance_pdf_viewer2/advance_pdf_viewer.dart';
import 'package:flutter/material.dart';

import 'package:photo_view/photo_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class DocumentViewer extends StatefulWidget {
  final String url;
  final String fileName;

  const DocumentViewer({
    Key? key,
    required this.url,
    required this.fileName,
  }) : super(key: key);

  @override
  _DocumentViewerState createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  bool _isLoading = true;
  String? _localPath;
  String? _error;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _downloadFile();
  }

  Future<void> _downloadFile() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        _localPath = path.join(dir.path, widget.fileName);
        final file = File(_localPath!);
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load document';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading document: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveDocument() async {
    if (_localPath == null) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }

        final savedFile = File(path.join(downloadDir.path, widget.fileName));
        await File(_localPath!).copy(savedFile.path);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document saved to Downloads')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission denied')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving document: $e')),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          if (!_isLoading && _error == null)
            IconButton(
              icon: Icon(_isDownloading ? Icons.downloading : Icons.download),
              onPressed: _isDownloading ? null : _saveDocument,
            ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _localPath == null
                ? null
                : () => Share.shareXFiles([XFile(_localPath!)]),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_localPath == null) {
      return Center(child: Text('No document available'));
    }

    final extension = path.extension(widget.fileName).toLowerCase();
    if (extension == '.pdf') {
      // return FutureBuilder<PDFDocument>(
      //   future: PDFDocument.fromFile(File(_localPath!)),
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return Center(child: CircularProgressIndicator());
      //     }
          
      //     if (snapshot.hasError) {
      //       return Center(child: Text('Error loading PDF: ${snapshot.error}'));
      //     }

      //     if (!snapshot.hasData) {
      //       return Center(child: Text('Failed to load PDF'));
      //     }

          return Container();
          //  PDFViewer(
          //   document: snapshot.data!,
          //   showPicker: false,
          //   showNavigation: true,
          // );
      //   },
      // );
    } else if (['.jpg', '.jpeg', '.png'].contains(extension)) {
      return PhotoView(
        imageProvider: FileImage(File(_localPath!)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      );
    }

    return Center(child: Text('Unsupported file type'));
  }
}
