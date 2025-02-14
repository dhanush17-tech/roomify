import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';

class FilterSheet extends StatefulWidget {
  final double? selectedMinPrice;
  final double? selectedMaxPrice;
  final int? selectedBedrooms;
  final int? selectedBathrooms;
  final double selectedRadius;
  final Function(double?, double?, int?, int?, double) onApplyFilters;

  const FilterSheet({
    Key? key,
    this.selectedMinPrice,
    this.selectedMaxPrice,
    this.selectedBedrooms,
    this.selectedBathrooms,
    required this.selectedRadius,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  _FilterSheetState createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late RangeValues _priceRange;
  int? _bedrooms;
  int? _bathrooms;
  late double _radius;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      widget.selectedMinPrice ?? 0,
      widget.selectedMaxPrice ?? 10000,
    );
    _bedrooms = widget.selectedBedrooms;
    _bathrooms = widget.selectedBathrooms;
    _radius = widget.selectedRadius;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  //reset filters
                  GestureDetector(
                    onTap: () {
                      widget.onApplyFilters(
                        null,
                        null,
                        null,
                        null,
                        10,
                      );
                      Navigator.pop(context);
                    },
                    child: Text('Reset Filters'),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Price Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 100,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          SizedBox(height: 20),
          Text(
            'Bedrooms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text('Any'),
                  selected: _bedrooms == null,
                  onSelected: (selected) {
                    setState(() {
                      _bedrooms = null;
                    });
                  },
                ),
                ...List.generate(5, (index) {
                  return Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text('${index + 1}'),
                      selected: _bedrooms == index + 1,
                      onSelected: (selected) {
                        setState(() {
                          _bedrooms = selected ? index + 1 : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Bathrooms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text('Any'),
                  selected: _bathrooms == null,
                  onSelected: (selected) {
                    setState(() {
                      _bathrooms = null;
                    });
                  },
                ),
                ...List.generate(4, (index) {
                  return Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text('${index + 1}'),
                      selected: _bathrooms == index + 1,
                      onSelected: (selected) {
                        setState(() {
                          _bathrooms = selected ? index + 1 : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Search Radius (miles)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: _radius,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${_radius.round()} miles',
            onChanged: (value) {
              setState(() {
                _radius = value;
              });
            },
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                widget.onApplyFilters(
                  _priceRange.start,
                  _priceRange.end,
                  _bedrooms,
                  _bathrooms,
                  _radius,
                );
                Navigator.pop(context);
              },
              child: Text(
                'Apply Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
