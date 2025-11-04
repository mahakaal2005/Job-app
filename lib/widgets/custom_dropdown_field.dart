import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';

class DropdownItem {
  final String value;
  final String label;
  final String? icon; // Optional emoji or icon

  DropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class CustomDropdownField extends StatefulWidget {
  final String labelText;
  final String hintText;
  final String? value;
  final List<DropdownItem> items;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final bool enableSearch;
  final IconData? prefixIcon;
  final String modalTitle;

  const CustomDropdownField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.enableSearch = true,
    this.prefixIcon,
    this.modalTitle = 'Select Option',
  });

  @override
  State<CustomDropdownField> createState() => _CustomDropdownFieldState();
}

class _CustomDropdownFieldState extends State<CustomDropdownField> {
  final TextEditingController _searchController = TextEditingController();
  List<DropdownItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        final queryLower = query.toLowerCase();
        _filteredItems = widget.items.where((item) {
          return item.label.toLowerCase().contains(queryLower) ||
              item.value.toLowerCase().contains(queryLower);
        }).toList();
      }
    });
  }

  void _showPicker() {
    _searchController.clear();
    _filteredItems = widget.items;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.modalTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Search field (only if enabled and more than 5 items)
              if (widget.enableSearch && widget.items.length > 5)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setModalState(() {
                                  _filterItems('');
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        _filterItems(value);
                      });
                    },
                  ),
                ),

              if (widget.enableSearch && widget.items.length > 5)
                const SizedBox(height: 8),

              // Items list
              Expanded(
                child: _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No options found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final isSelected = item.value == widget.value;

                          return ListTile(
                            leading: item.icon != null
                                ? Text(
                                    item.icon!,
                                    style: const TextStyle(fontSize: 24),
                                  )
                                : null,
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor:
                                AppColors.lookGigPurple.withOpacity(0.1),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.lookGigPurple,
                                  )
                                : null,
                            onTap: () {
                              widget.onChanged(item.value);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => DropdownItem(value: '', label: widget.hintText),
    );

    // Determine if we should show placeholder text
    final bool showPlaceholder = widget.value == null || widget.value!.isEmpty;
    final String displayText = showPlaceholder ? widget.hintText : selectedItem.label;

    return TextFormField(
      readOnly: true,
      style: TextStyle(
        color: showPlaceholder ? AppColors.hintText : Colors.black, // Grey when placeholder, black when selected
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: AppColors.hintText),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        prefixIcon: widget.prefixIcon != null 
            ? Icon(widget.prefixIcon, color: const Color(0xFF2F51A7))
            : null,
      ),
      controller: TextEditingController(text: displayText),
      onTap: _showPicker,
      validator: widget.validator,
    );
  }
}
