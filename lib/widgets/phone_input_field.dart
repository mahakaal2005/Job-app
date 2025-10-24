import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_work_app/utils/app_colors.dart';

class CountryCode {
  final String name;
  final String dialCode;
  final String code;
  final String flag;
  final int minLength;
  final int maxLength;

  CountryCode({
    required this.name,
    required this.dialCode,
    required this.code,
    required this.flag,
    required this.minLength,
    required this.maxLength,
  });
}

class PhoneInputField extends StatefulWidget {
  final TextEditingController phoneController;
  final String? Function(String?)? validator;
  final String labelText;
  final String hintText;
  final Function(String)? onCountryCodeChanged;

  const PhoneInputField({
    super.key,
    required this.phoneController,
    this.validator,
    this.labelText = 'Phone Number *',
    this.hintText = 'Enter phone number',
    this.onCountryCodeChanged,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  String _selectedCountryCode = '+91'; // Default to India
  final TextEditingController _searchController = TextEditingController();
  List<CountryCode> _filteredCountries = [];

  // Popular countries list with phone length validation
  final List<CountryCode> _countries = [
    CountryCode(name: 'India', dialCode: '+91', code: 'IN', flag: '🇮🇳', minLength: 10, maxLength: 10),
    CountryCode(name: 'United States', dialCode: '+1', code: 'US', flag: '🇺🇸', minLength: 10, maxLength: 10),
    CountryCode(name: 'United Kingdom', dialCode: '+44', code: 'GB', flag: '🇬🇧', minLength: 10, maxLength: 10),
    CountryCode(name: 'Canada', dialCode: '+1', code: 'CA', flag: '🇨🇦', minLength: 10, maxLength: 10),
    CountryCode(name: 'Australia', dialCode: '+61', code: 'AU', flag: '🇦🇺', minLength: 9, maxLength: 9),
    CountryCode(name: 'Germany', dialCode: '+49', code: 'DE', flag: '🇩🇪', minLength: 10, maxLength: 11),
    CountryCode(name: 'France', dialCode: '+33', code: 'FR', flag: '🇫🇷', minLength: 9, maxLength: 9),
    CountryCode(name: 'Japan', dialCode: '+81', code: 'JP', flag: '🇯🇵', minLength: 10, maxLength: 10),
    CountryCode(name: 'China', dialCode: '+86', code: 'CN', flag: '🇨🇳', minLength: 11, maxLength: 11),
    CountryCode(name: 'Brazil', dialCode: '+55', code: 'BR', flag: '🇧🇷', minLength: 10, maxLength: 11),
    CountryCode(name: 'Russia', dialCode: '+7', code: 'RU', flag: '🇷🇺', minLength: 10, maxLength: 10),
    CountryCode(name: 'South Korea', dialCode: '+82', code: 'KR', flag: '🇰🇷', minLength: 9, maxLength: 10),
    CountryCode(name: 'Mexico', dialCode: '+52', code: 'MX', flag: '🇲🇽', minLength: 10, maxLength: 10),
    CountryCode(name: 'Italy', dialCode: '+39', code: 'IT', flag: '🇮🇹', minLength: 9, maxLength: 10),
    CountryCode(name: 'Spain', dialCode: '+34', code: 'ES', flag: '🇪🇸', minLength: 9, maxLength: 9),
    CountryCode(name: 'Netherlands', dialCode: '+31', code: 'NL', flag: '🇳🇱', minLength: 9, maxLength: 9),
    CountryCode(name: 'Switzerland', dialCode: '+41', code: 'CH', flag: '🇨🇭', minLength: 9, maxLength: 9),
    CountryCode(name: 'Sweden', dialCode: '+46', code: 'SE', flag: '🇸🇪', minLength: 9, maxLength: 10),
    CountryCode(name: 'Singapore', dialCode: '+65', code: 'SG', flag: '🇸🇬', minLength: 8, maxLength: 8),
    CountryCode(name: 'UAE', dialCode: '+971', code: 'AE', flag: '🇦🇪', minLength: 9, maxLength: 9),
    CountryCode(name: 'Saudi Arabia', dialCode: '+966', code: 'SA', flag: '🇸🇦', minLength: 9, maxLength: 9),
    CountryCode(name: 'South Africa', dialCode: '+27', code: 'ZA', flag: '🇿🇦', minLength: 9, maxLength: 9),
    CountryCode(name: 'Pakistan', dialCode: '+92', code: 'PK', flag: '🇵🇰', minLength: 10, maxLength: 10),
    CountryCode(name: 'Bangladesh', dialCode: '+880', code: 'BD', flag: '🇧🇩', minLength: 10, maxLength: 10),
    CountryCode(name: 'Sri Lanka', dialCode: '+94', code: 'LK', flag: '🇱🇰', minLength: 9, maxLength: 9),
    CountryCode(name: 'Nepal', dialCode: '+977', code: 'NP', flag: '🇳🇵', minLength: 10, maxLength: 10),
    CountryCode(name: 'Malaysia', dialCode: '+60', code: 'MY', flag: '🇲🇾', minLength: 9, maxLength: 10),
    CountryCode(name: 'Indonesia', dialCode: '+62', code: 'ID', flag: '🇮🇩', minLength: 10, maxLength: 12),
    CountryCode(name: 'Thailand', dialCode: '+66', code: 'TH', flag: '🇹🇭', minLength: 9, maxLength: 9),
    CountryCode(name: 'Philippines', dialCode: '+63', code: 'PH', flag: '🇵🇭', minLength: 10, maxLength: 10),
    CountryCode(name: 'Vietnam', dialCode: '+84', code: 'VN', flag: '🇻🇳', minLength: 9, maxLength: 10),
    CountryCode(name: 'Turkey', dialCode: '+90', code: 'TR', flag: '🇹🇷', minLength: 10, maxLength: 10),
    CountryCode(name: 'Poland', dialCode: '+48', code: 'PL', flag: '🇵🇱', minLength: 9, maxLength: 9),
    CountryCode(name: 'Argentina', dialCode: '+54', code: 'AR', flag: '🇦🇷', minLength: 10, maxLength: 10),
    CountryCode(name: 'Chile', dialCode: '+56', code: 'CL', flag: '🇨🇱', minLength: 9, maxLength: 9),
    CountryCode(name: 'Colombia', dialCode: '+57', code: 'CO', flag: '🇨🇴', minLength: 10, maxLength: 10),
    CountryCode(name: 'Egypt', dialCode: '+20', code: 'EG', flag: '🇪🇬', minLength: 10, maxLength: 10),
    CountryCode(name: 'Nigeria', dialCode: '+234', code: 'NG', flag: '🇳🇬', minLength: 10, maxLength: 10),
    CountryCode(name: 'Kenya', dialCode: '+254', code: 'KE', flag: '🇰🇪', minLength: 9, maxLength: 9),
    CountryCode(name: 'New Zealand', dialCode: '+64', code: 'NZ', flag: '🇳🇿', minLength: 9, maxLength: 10),
  ];

  @override
  void initState() {
    super.initState();
    _filteredCountries = _countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = _countries;
      } else {
        final queryLower = query.toLowerCase();
        _filteredCountries = _countries.where((country) {
          return country.name.toLowerCase().contains(queryLower) ||
              country.dialCode.contains(query) ||
              country.code.toLowerCase().contains(queryLower);
        }).toList();
      }
    });
  }

  void _showCountryPicker() {
    _searchController.clear();
    _filteredCountries = _countries;

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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Country Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search country or code...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setModalState(() {
                                _filterCountries('');
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
                      _filterCountries(value);
                    });
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Countries list
              Expanded(
                child: _filteredCountries.isEmpty
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
                              'No countries found',
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
                        itemCount: _filteredCountries.length,
                        itemBuilder: (context, index) {
                          final country = _filteredCountries[index];
                          final isSelected =
                              country.dialCode == _selectedCountryCode;

                          return ListTile(
                            title: Text(
                              country.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: Text(
                              country.dialCode,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.lookGigPurple
                                    : Colors.grey[600],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor:
                                AppColors.lookGigPurple.withOpacity(0.1),
                            onTap: () {
                              setState(() {
                                _selectedCountryCode = country.dialCode;
                              });
                              widget.onCountryCodeChanged
                                  ?.call(country.dialCode);
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
    final selectedCountry = _countries.firstWhere(
      (c) => c.dialCode == _selectedCountryCode,
      orElse: () => _countries[0],
    );

    return Row(
      children: [
        // Country code dropdown
        Expanded(
          flex: 2,
          child: TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: 'Code',
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            controller: TextEditingController(text: _selectedCountryCode),
            onTap: _showCountryPicker,
          ),
        ),
        const SizedBox(width: 12),
        // Phone number field
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: widget.phoneController,
            decoration: const InputDecoration(
              labelText: '', // Empty to avoid duplicate label
              hintText: '1234567890',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(selectedCountry.maxLength),
            ],
            validator: (value) {
              if (widget.validator != null) {
                return widget.validator!(value);
              }
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
              if (cleaned.length < selectedCountry.minLength) {
                return 'Invalid phone number';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}
