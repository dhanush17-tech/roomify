import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PDFViewerScreen extends StatefulWidget {
  final File file;

  const PDFViewerScreen({Key? key, required this.file}) : super(key: key);

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _pdfReady = false;
  PDFViewController? _pdfViewController;
  bool _isLoading = true;
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      if (widget.file.path.startsWith('http')) {
        // If it's a URL, download the file first
        final tempDir = await getTemporaryDirectory();
        final fileName = widget.file.path.split('/').last;
        final tempFile = File('${tempDir.path}/$fileName');

        if (await tempFile.exists()) {
          setState(() {
            _pdfPath = tempFile.path;
            _isLoading = false;
          });
          return;
        }

        final response = await http.get(Uri.parse(widget.file.path));
        await tempFile.writeAsBytes(response.bodyBytes);
        setState(() {
          _pdfPath = tempFile.path;
          _isLoading = false;
        });
      } else {
        setState(() {
          _pdfPath = widget.file.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.path.split('/').last),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () async {
              await Share.shareXFiles([XFile(widget.file.path)]);
            },
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () async {
              try {
                final downloadDir = Directory('/storage/emulated/0/Download');
                if (!await downloadDir.exists()) {
                  await downloadDir.create(recursive: true);
                }

                final savedFile = File(
                    '${downloadDir.path}/${widget.file.path.split('/').last}');
                await widget.file.copy(savedFile.path);

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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _pdfPath == null
              ? Center(child: Text('Error loading PDF'))
              : Stack(
                  children: [
                    PDFView(
                      filePath: _pdfPath!,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      autoSpacing: true,
                      pageFling: true,
                      pageSnap: true,
                      defaultPage: 0,
                      fitPolicy: FitPolicy.BOTH,
                      preventLinkNavigation: false,
                      onRender: (pages) {
                        setState(() {
                          _totalPages = pages!;
                          _pdfReady = true;
                        });
                      },
                      onViewCreated: (PDFViewController vc) {
                        setState(() {
                          _pdfViewController = vc;
                        });
                      },
                      onPageChanged: (int? page, int? total) {
                        if (page != null) {
                          setState(() {
                            _currentPage = page;
                          });
                        }
                      },
                      onError: (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error loading PDF: $error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),
                    if (_pdfReady)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(Icons.chevron_left),
                                iconSize: 40,
                                color: Colors.black87,
                                onPressed: _currentPage > 0
                                    ? () {
                                        _pdfViewController
                                            ?.setPage(_currentPage - 1);
                                      }
                                    : null,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_currentPage + 1} / $_totalPages',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.chevron_right),
                                iconSize: 40,
                                color: Colors.black87,
                                onPressed: _currentPage < _totalPages - 1
                                    ? () {
                                        _pdfViewController
                                            ?.setPage(_currentPage + 1);
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
