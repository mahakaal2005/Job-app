import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime) onDateSelected;
  final String title;

  const CustomDatePicker({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    required this.onDateSelected,
    this.title = 'End Date',
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late PageController _monthController;
  late PageController _yearController;
  
  late int _selectedMonth;
  late int _selectedYear;
  
  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  
  late List<int> _years;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize date range
    final now = DateTime.now();
    final firstYear = widget.firstDate?.year ?? (now.year - 50);
    final lastYear = widget.lastDate?.year ?? now.year;
    
    _years = List.generate(lastYear - firstYear + 1, (index) => firstYear + index);
    
    // Initialize selected values
    final initialDate = widget.initialDate ?? now;
    _selectedMonth = initialDate.month;
    _selectedYear = initialDate.year;
    
    // Initialize controllers with selected values centered
    _monthController = PageController(
      initialPage: _selectedMonth - 1,
      viewportFraction: 0.3,
    );
    
    final yearIndex = _years.indexOf(_selectedYear);
    _yearController = PageController(
      initialPage: yearIndex >= 0 ? yearIndex : 0,
      viewportFraction: 0.3,
    );
  }
  
  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }
  
  void _onSave() {
    final selectedDate = DateTime(_selectedYear, _selectedMonth);
    widget.onDateSelected(selectedDate);
    Navigator.of(context).pop();
  }
  
  void _onCancel() {
    Navigator.of(context).pop();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background overlay
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF2C373B).withOpacity(0.6),
        ),
        
        // Modal content - centered on screen
        Center(
          child: Container(
            width: 335,
            height: 449,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF99ABC6).withOpacity(0.18),
                  blurRadius: 62,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Close button - centered horizontally at top
                Padding(
                  padding: const EdgeInsets.only(top: 25),
                  child: Center(
                    child: GestureDetector(
                      onTap: _onCancel,
                      child: Container(
                        width: 30,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B5858),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // Title
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.362,
                    color: Color(0xFF150B3D),
                    decoration: TextDecoration.none,
                  ),
                ),
                
                const SizedBox(height: 52),
                
                // Date selection wheels
                Expanded(
                  child: Row(
                    children: [
                      // Month selector
                      Expanded(
                        child: _buildMonthSelector(),
                      ),
                      
                      // Divider line
                      Container(
                        width: 0.5,
                        height: 78,
                        color: const Color(0xFFDCDCDC),
                      ),
                      
                      // Year selector
                      Expanded(
                        child: _buildYearSelector(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 37),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 59),
                  child: Column(
                    children: [
                      // Save button
                      GestureDetector(
                        onTap: _onSave,
                        child: Container(
                          width: 217,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF130160),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF99ABC6).withOpacity(0.18),
                                blurRadius: 62,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'SAVE',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.302,
                                letterSpacing: 0.84,
                                color: AppColors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Cancel button
                      GestureDetector(
                        onTap: _onCancel,
                        child: Container(
                          width: 217,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6CDFE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(
                            child: Text(
                              'CANCEL',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.302,
                                letterSpacing: 0.84,
                                color: AppColors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMonthSelector() {
    return SizedBox(
      height: 108,
      child: PageView.builder(
        controller: _monthController,
        onPageChanged: (index) {
          setState(() {
            _selectedMonth = index + 1;
          });
        },
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final isSelected = index + 1 == _selectedMonth;
          
          return Center(
            child: GestureDetector(
              onTap: () {
                _monthController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                width: isSelected ? 50 : 30,
                height: isSelected ? 108 : 52,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF2F51A7) 
                      : const Color(0xFFC4C4C4).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(isSelected ? 15 : 10),
                ),
                child: Center(
                  child: Text(
                    _months[index],
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: isSelected ? 14 : 10,
                      height: 1.362,
                      color: AppColors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildYearSelector() {
    return SizedBox(
      height: 108,
      child: PageView.builder(
        controller: _yearController,
        onPageChanged: (index) {
          setState(() {
            _selectedYear = _years[index];
          });
        },
        itemCount: _years.length,
        itemBuilder: (context, index) {
          final year = _years[index];
          final isSelected = year == _selectedYear;
          
          return Center(
            child: GestureDetector(
              onTap: () {
                _yearController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                width: isSelected ? 50 : 30,
                height: isSelected ? 108 : 52,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF2F51A7) 
                      : const Color(0xFFC4C4C4).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(isSelected ? 15 : 10),
                ),
                child: Center(
                  child: Text(
                    year.toString(),
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: isSelected ? 14 : 10,
                      height: 1.362,
                      color: AppColors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Helper function to show the custom date picker
Future<DateTime?> showCustomDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String title = 'End Date',
}) async {
  DateTime? selectedDate;
  
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => CustomDatePicker(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
      onDateSelected: (date) {
        selectedDate = date;
      },
    ),
  );
  
  return selectedDate;
}
