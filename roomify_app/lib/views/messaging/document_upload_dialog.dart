import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class DocumentUploadDialog extends StatefulWidget {
  final String requestId;
  final Function(List<File>) onSubmit;

  DocumentUploadDialog({
    required this.requestId,
    required this.onSubmit,
  });

  @override
  _DocumentUploadDialogState createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<DocumentUploadDialog> {
  final List<File> selectedFiles = [];
  bool isUploading = false;

  Future<void> _pickAndUploadFiles() async {
    try {
      // Allow both images and PDFs
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: true,
      );

      if (result == null) return;

      setState(() {
        isUploading = true;
        selectedFiles.addAll(
          result.paths.where((path) => path != null).map((path) => File(path!)),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting files: $e')),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Upload Documents'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...selectedFiles.asMap().entries.map((entry) => ListTile(
                  leading: Icon(
                    entry.value.path.toLowerCase().endsWith('.pdf')
                        ? Icons.picture_as_pdf
                        : Icons.image,
                  ),
                  title: Text(entry.value.path.split('/').last),
                  trailing: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => _removeFile(entry.key),
                  ),
                )),
            if (isUploading)
              Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _pickAndUploadFiles,
                  icon: Icon(Icons.add),
                  label: Text('Add Documents'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedFiles.isEmpty
              ? null
              : () {
                  widget.onSubmit(selectedFiles);
                  Navigator.pop(context);
                },
          child: Text('Submit'),
        ),
      ],
    );
  }
}
