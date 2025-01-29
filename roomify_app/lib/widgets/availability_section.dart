import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';

class AvailabilitySection extends StatelessWidget {
  final String? moveInDate;
  final String? moveOutDate;
  final Function(BuildContext, bool, bool) onSelectDate;

  const AvailabilitySection({
    Key? key,
    required this.moveInDate,
    required this.moveOutDate,
    required this.onSelectDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: blackTextColor,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showMoveInOptions(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Move-in Date *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: moveInDate == null ? 'Required' : null,
                  ),
                  child: Text(
                    moveInDate ?? 'Select Date',
                    style: TextStyle(
                      color: moveInDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => onSelectDate(context, false, false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Move-out Date (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    moveOutDate ?? 'Select Date',
                    style: TextStyle(
                      color: moveOutDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showMoveInOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move-in Date'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Anytime'),
              onTap: () {
                Navigator.pop(context);
                onSelectDate(context, true, true);
              },
            ),
            ListTile(
              title: Text('Select Specific Date'),
              onTap: () {
                Navigator.pop(context);
                onSelectDate(context, true, false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
