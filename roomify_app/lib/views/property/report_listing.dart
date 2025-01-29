import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/repository/properties_repo.dart';
import 'package:roomify_app/views/home/bottom_nav.dart';

class ReportScreen extends StatefulWidget {
  final int listingId;
  final String listingType;
  double latitude;
  double longitude;
  ReportScreen({
    required this.listingId,
    required this.listingType,
    required this.latitude,
    required this.longitude,
    super.key,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String reasonForReport = "";
  bool _isLoading = false;
  final _repository = PropertyRepository();
  final TextEditingController _detailsController = TextEditingController();

  Future<void> _submitReport() async {
    if (reasonForReport.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _repository.reportProperty(
        widget.listingId,
        reasonForReport,
        _detailsController.text,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Report submitted successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh providers before navigation
      await Provider.of<AuthProvider>(context, listen: false)
          .refreshAllProviders(context);

      // Delay pop to show snackbar
      if (mounted) {
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => MainScreen(
                      latitude: widget.latitude,
                      longitude: widget.longitude,
                    )),
            (route) => false,
          );
        });
      }
    } on AlreadyReportedException catch (e) {
      if (!mounted) return;

      // Show already reported dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Already Reported'),
            ],
          ),
          content: Text(
            'You have already reported this listing. Our team is will reach out to you soon.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Failed to submit report: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).viewPadding.top),
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, color: blackTextColor),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Why are you reporting ${widget.listingType}?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: blackTextColor.withOpacity(0.85),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "This won't be shared with the host.",
                    style: AppTextStyles.caption(),
                  ),
                  SizedBox(height: 15),
                  _buildReportOptions(),
                  if (reasonForReport.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Text(
                      "Additional Details (Optional)",
                      style: AppTextStyles.subtitle(color: blackTextColor),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _detailsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Provide any additional details...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildSubmitButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOptions() {
    final options = [
      "The information was inaccurate",
      "It's not a real place/item",
      "It's a scam",
      "It's a duplicate listing",
      "The host is asking for more money than listed",
    ];

    return Column(
      children: options.map((option) {
        return Column(
          children: [
            _buildRadioOption(option),
            Divider(height: 1.5),
            SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRadioOption(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: blackTextColor,
            ),
          ),
        ),
        Radio(
          value: title.toLowerCase(),
          groupValue: reasonForReport,
          onChanged: (value) => setState(() => reasonForReport = value!),
          activeColor: orangeColor,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1.5),
          SizedBox(height: 20),
          GestureDetector(
            onTap: _isLoading || reasonForReport.isEmpty ? null : _submitReport,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: reasonForReport.isEmpty
                    ? Colors.grey
                    : orangeColor.withOpacity(0.89),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Submit Report",
                        style: TextStyle(
                          fontSize: 21,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}
