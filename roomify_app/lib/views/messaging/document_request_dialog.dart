import 'package:flutter/material.dart';
import 'package:roomify_app/models/chatModel.dart';

class DocumentRequestDialog extends StatefulWidget {
  final String recipientId;
  final Function(List<DocumentType>, {String? customDocumentName}) onRequest;

  DocumentRequestDialog({
    required this.recipientId,
    required this.onRequest,
  });

  @override
  _DocumentRequestDialogState createState() => _DocumentRequestDialogState();
}

class _DocumentRequestDialogState extends State<DocumentRequestDialog> {
  final Set<DocumentType> selectedDocuments = {};
  final TextEditingController _customDocController = TextEditingController();
  bool _showCustomInput = false;
  String? _customDocumentName;

  @override
  void dispose() {
    _customDocController.dispose();
    super.dispose();
  }

  String _getDocumentDisplayName(DocumentType type) {
    return type
        .toString()
        .split('.')
        .last
        .replaceAll(RegExp(r'(?=[A-Z])'), ' ')
        .capitalize();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Request Documents'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select the documents you want to request:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            Divider(),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Add Custom Document'),
              onTap: () {
                setState(() {
                  _showCustomInput = !_showCustomInput;
                });
              },
            ),
            if (_showCustomInput) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _customDocController,
                  decoration: InputDecoration(
                    labelText: 'Custom Document Name',
                    hintText: 'Enter document name',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add_circle),
                      onPressed: () {
                        if (_customDocController.text.isNotEmpty) {
                          setState(() {
                            selectedDocuments.add(DocumentType.Custom);
                            _customDocumentName = _customDocController.text;
                          });
                          _customDocController.clear();
                          _showCustomInput = false;
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
            Divider(),
            ...DocumentType.values
                .where((type) => type != DocumentType.Custom)
                .map((type) => CheckboxListTile(
                      title: Text(_getDocumentDisplayName(type)),
                      subtitle: Text(_getDocumentDescription(type)),
                      value: selectedDocuments.contains(type),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedDocuments.add(type);
                          } else {
                            selectedDocuments.remove(type);
                          }
                        });
                      },
                    )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedDocuments.isEmpty
              ? null
              : () {
                  widget.onRequest(
                    selectedDocuments.toList(),
                    customDocumentName: _customDocumentName,
                  );
                  Navigator.pop(context);
                },
          child: Text('Request'),
        ),
      ],
    );
  }

  String _getDocumentDescription(DocumentType type) {
    switch (type) {
      case DocumentType.Passport:
        return 'Valid passport for identification';
      case DocumentType.DriverLicense:
        return 'Current driver\'s license';
      case DocumentType.StudentId:
        return 'Valid student identification card';
      case DocumentType.BankStatement:
        return 'Recent bank statement (last 3 months)';
      case DocumentType.EmploymentLetter:
        return 'Letter from current employer';
      case DocumentType.UtilityBill:
        return 'Recent utility bill for address verification';
      case DocumentType.Custom:
        return 'Custom document request';
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
