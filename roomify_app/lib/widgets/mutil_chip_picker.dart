import 'dart:io';

import 'package:flutter/material.dart';

typedef OnChanged = void Function(List<FilterChipData> data);

class MultiChipPicker extends StatefulWidget {
  final List<FilterChipData>? filterChips; // List of filter chips
  final OnChanged? onChanged; // Callback when filter chips are changed
  final bool? isEnabled; // Whether the filter chips are enabled
  final bool? isSelected; // Whether the filter chips are selected
  final Widget? avatar; // Avatar widget for filter chips
  final TextStyle? labelStyle; // Style for the filter chip labels
  final double? pressElevation; // Elevation when filter chip is pressed
  final Color? disabledColor; // Color for disabled filter chips
  final Color? selectedColor; // Color for selected filter chips
  final String? tooltip; // Tooltip for filter chips
  final ShapeBorder? avatarBorder; // Border shape for filter chip avatars
  final BorderSide? side; // Border side for filter chips
  final Clip? clipBehavior; // Clip behavior for filter chips
  final FocusNode? focusNode; // Focus node for filter chips
  final bool? autofocus; // Whether the filter chips should autofocus
  final Color? backgroundColor; // Background color for filter chips
  final EdgeInsetsGeometry? labelPadding; // Padding for filter chip labels
  final VisualDensity? visualDensity; // Visual density for filter chips
  final Color? surfaceTintColor; // Surface tint color for filter chips
  final IconThemeData? iconTheme; // Icon theme for filter chips
  final Color? selectedShadowColor; // Shadow color for selected filter chips
  final bool?
      showCheckmark; // Whether to show a checkmark for selected filter chips
  final Color?
      checkmarkColor; // Color for the checkmark on selected filter chips
  final EdgeInsetsGeometry? padding; // Padding for filter chips
  final OutlinedBorder? shape; // Shape for filter chips
  final bool?
      isSelectedShadowColor; // Whether to use shadow color for selected filter chips
  final double? filterChipSpacing; //Spacing between each filter chip
  final Color? selectedTextColor;
  const MultiChipPicker({
    Key? key,
    required this.filterChips,
    required this.onChanged,
    this.avatar,
    this.autofocus,
    this.avatarBorder,
    this.backgroundColor,
    this.checkmarkColor,
    this.clipBehavior,
    this.disabledColor,
    this.focusNode,
    this.iconTheme,
    this.isEnabled,
    this.isSelected,
    this.isSelectedShadowColor,
    this.labelPadding,
    this.labelStyle,
    this.padding,
    this.pressElevation,
    this.selectedColor,
    this.selectedTextColor,
    this.selectedShadowColor,
    this.shape,
    this.showCheckmark,
    this.side,
    this.surfaceTintColor,
    this.tooltip,
    this.visualDensity,
    this.filterChipSpacing,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MultiChipPickerState createState() => _MultiChipPickerState();

  String? getPlatformVersion() {
    return Platform.version;
  }
}

class _MultiChipPickerState extends State<MultiChipPicker> {
  List<FilterChipData> filteredChipData = []; // Selected filter chips

  void _onChipSelected(FilterChipData chipData, bool selected) {
    setState(() {
      for (var element in widget.filterChips!) {
        if (element == chipData) {
          setState(() {
            element.isSelected = !element.isSelected;
          });
        }
      }
      chipData.isSelected = selected;
      if (chipData.isSelected) {
        filteredChipData.add(chipData);
      } else {
        filteredChipData.removeWhere((item) => item.id == chipData.id);
      }
    });
    widget.onChanged?.call(filteredChipData);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 10,
      alignment: WrapAlignment.center,
      spacing: widget.filterChipSpacing ?? 8.0,
      children: widget.filterChips?.map((chipData) {
            return FilterChip(
              label: Text(chipData.label), // Label for the filter chip
              selected:
                  chipData.isSelected, // Whether the filter chip is selected
              onSelected: (bool selected) {
                _onChipSelected(chipData, selected);
              },
              key: widget.key,
              avatar: widget.avatar, // Avatar widget for the filter chip
              labelStyle: widget.labelStyle ??
                  TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: chipData.isSelected == true
                          ? widget.selectedTextColor
                          : const Color.fromARGB(255, 104, 103,
                              103)), // Style for the filter chip label
              labelPadding: widget.labelPadding ??
                  const EdgeInsets.all(
                      3.0), // Padding for the filter chip label
              pressElevation: widget
                  .pressElevation, // Elevation when filter chip is pressed
              disabledColor:
                  widget.disabledColor, // Color for disabled filter chips
              selectedColor: widget.selectedColor ??
                  const Color.fromARGB(255, 0, 134, 243)
                      .withOpacity(0.1), // Color for selected filter chips
              tooltip: widget.tooltip, // Border side for filter chips
              side: widget.side ??
                  (chipData.isSelected == true
                      ? const BorderSide(color: Colors.transparent, width: 0.0)
                      : const BorderSide(color: Colors.grey, width: 0.9)),
              shape: widget.shape ??
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  ), // Shape for filter chips
              focusNode: widget.focusNode, // Focus node for filter chips
              backgroundColor: widget.backgroundColor ??
                  Colors.transparent, // Background color for filter chips
              padding: widget.padding ??
                  const EdgeInsets.all(10.0), // Padding for filter chips
              visualDensity:
                  widget.visualDensity, // Visual density for filter chips
              surfaceTintColor: widget
                  .surfaceTintColor, // Surface tint color for filter chips
              iconTheme: widget.iconTheme ??
                  const IconThemeData(
                      color: Color.fromARGB(
                          255, 0, 134, 243)), // Icon theme for filter chips
              selectedShadowColor: widget
                  .selectedShadowColor, // Shadow color for selected filter chips
              showCheckmark: widget
                  .showCheckmark, // Whether to show a checkmark for selected filter chips
              checkmarkColor: widget.checkmarkColor ??
                  const Color.fromARGB(255, 0, 134,
                      243), // Color for the checkmark on selected filter chips

              avatarBorder: widget.avatarBorder ??
                  const CircleBorder(), // Border shape for filter chip avatars
            );
          }).toList() ??
          [], // Convert filter chip data to filter chip widgets
    );
  }
}

class FilterChipData {
  final String label; // Label for the filter chip
  bool isSelected; // Whether the filter chip is selected
  static int _idCounter = 0;
  int id = 0;

  FilterChipData(this.label, this.isSelected)
      : id = getNextId(); // Assign a unique ID to each filter chip data

  static int getNextId() {
    _idCounter++; // Increment the ID counter
    return _idCounter;
  }
}
