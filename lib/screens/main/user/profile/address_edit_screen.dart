import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/widgets/custom_dropdown_field.dart';

class AddressEditScreen extends StatefulWidget {
  const AddressEditScreen({super.key});

  @override
  State<AddressEditScreen> createState() => _AddressEditScreenState();
}

class _AddressEditScreenState extends State<AddressEditScreen> {
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  String? _selectedCity;
  String? _selectedState;
  String? _selectedCountry;

  bool _isSaving = false;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;

  Map<String, dynamic> _originalData = {};

  // Static data for different countries
  static final Map<String, List<DropdownItem>> _statesByCountry = {
    'US': [
      DropdownItem(value: 'AL', label: 'Alabama'),
      DropdownItem(value: 'AK', label: 'Alaska'),
      DropdownItem(value: 'AZ', label: 'Arizona'),
      DropdownItem(value: 'AR', label: 'Arkansas'),
      DropdownItem(value: 'CA', label: 'California'),
      DropdownItem(value: 'CO', label: 'Colorado'),
      DropdownItem(value: 'CT', label: 'Connecticut'),
      DropdownItem(value: 'DE', label: 'Delaware'),
      DropdownItem(value: 'FL', label: 'Florida'),
      DropdownItem(value: 'GA', label: 'Georgia'),
      DropdownItem(value: 'HI', label: 'Hawaii'),
      DropdownItem(value: 'ID', label: 'Idaho'),
      DropdownItem(value: 'IL', label: 'Illinois'),
      DropdownItem(value: 'IN', label: 'Indiana'),
      DropdownItem(value: 'IA', label: 'Iowa'),
      DropdownItem(value: 'KS', label: 'Kansas'),
      DropdownItem(value: 'KY', label: 'Kentucky'),
      DropdownItem(value: 'LA', label: 'Louisiana'),
      DropdownItem(value: 'ME', label: 'Maine'),
      DropdownItem(value: 'MD', label: 'Maryland'),
      DropdownItem(value: 'MA', label: 'Massachusetts'),
      DropdownItem(value: 'MI', label: 'Michigan'),
      DropdownItem(value: 'MN', label: 'Minnesota'),
      DropdownItem(value: 'MS', label: 'Mississippi'),
      DropdownItem(value: 'MO', label: 'Missouri'),
      DropdownItem(value: 'MT', label: 'Montana'),
      DropdownItem(value: 'NE', label: 'Nebraska'),
      DropdownItem(value: 'NV', label: 'Nevada'),
      DropdownItem(value: 'NH', label: 'New Hampshire'),
      DropdownItem(value: 'NJ', label: 'New Jersey'),
      DropdownItem(value: 'NM', label: 'New Mexico'),
      DropdownItem(value: 'NY', label: 'New York'),
      DropdownItem(value: 'NC', label: 'North Carolina'),
      DropdownItem(value: 'ND', label: 'North Dakota'),
      DropdownItem(value: 'OH', label: 'Ohio'),
      DropdownItem(value: 'OK', label: 'Oklahoma'),
      DropdownItem(value: 'OR', label: 'Oregon'),
      DropdownItem(value: 'PA', label: 'Pennsylvania'),
      DropdownItem(value: 'RI', label: 'Rhode Island'),
      DropdownItem(value: 'SC', label: 'South Carolina'),
      DropdownItem(value: 'SD', label: 'South Dakota'),
      DropdownItem(value: 'TN', label: 'Tennessee'),
      DropdownItem(value: 'TX', label: 'Texas'),
      DropdownItem(value: 'UT', label: 'Utah'),
      DropdownItem(value: 'VT', label: 'Vermont'),
      DropdownItem(value: 'VA', label: 'Virginia'),
      DropdownItem(value: 'WA', label: 'Washington'),
      DropdownItem(value: 'WV', label: 'West Virginia'),
      DropdownItem(value: 'WI', label: 'Wisconsin'),
      DropdownItem(value: 'WY', label: 'Wyoming'),
      DropdownItem(value: 'DC', label: 'District of Columbia'),
    ],
    'CA': [
      DropdownItem(value: 'AB', label: 'Alberta'),
      DropdownItem(value: 'BC', label: 'British Columbia'),
      DropdownItem(value: 'MB', label: 'Manitoba'),
      DropdownItem(value: 'NB', label: 'New Brunswick'),
      DropdownItem(value: 'NL', label: 'Newfoundland and Labrador'),
      DropdownItem(value: 'NS', label: 'Nova Scotia'),
      DropdownItem(value: 'ON', label: 'Ontario'),
      DropdownItem(value: 'PE', label: 'Prince Edward Island'),
      DropdownItem(value: 'QC', label: 'Quebec'),
      DropdownItem(value: 'SK', label: 'Saskatchewan'),
      DropdownItem(value: 'NT', label: 'Northwest Territories'),
      DropdownItem(value: 'NU', label: 'Nunavut'),
      DropdownItem(value: 'YT', label: 'Yukon'),
    ],
    'GB': [
      DropdownItem(value: 'ENG', label: 'England'),
      DropdownItem(value: 'SCT', label: 'Scotland'),
      DropdownItem(value: 'WLS', label: 'Wales'),
      DropdownItem(value: 'NIR', label: 'Northern Ireland'),
    ],
    'AU': [
      DropdownItem(value: 'NSW', label: 'New South Wales'),
      DropdownItem(value: 'VIC', label: 'Victoria'),
      DropdownItem(value: 'QLD', label: 'Queensland'),
      DropdownItem(value: 'WA', label: 'Western Australia'),
      DropdownItem(value: 'SA', label: 'South Australia'),
      DropdownItem(value: 'TAS', label: 'Tasmania'),
      DropdownItem(value: 'ACT', label: 'Australian Capital Territory'),
      DropdownItem(value: 'NT', label: 'Northern Territory'),
    ],
    'IN': [
      DropdownItem(value: 'AP', label: 'Andhra Pradesh'),
      DropdownItem(value: 'AR', label: 'Arunachal Pradesh'),
      DropdownItem(value: 'AS', label: 'Assam'),
      DropdownItem(value: 'BR', label: 'Bihar'),
      DropdownItem(value: 'CT', label: 'Chhattisgarh'),
      DropdownItem(value: 'DL', label: 'Delhi'),
      DropdownItem(value: 'GA', label: 'Goa'),
      DropdownItem(value: 'GJ', label: 'Gujarat'),
      DropdownItem(value: 'HR', label: 'Haryana'),
      DropdownItem(value: 'HP', label: 'Himachal Pradesh'),
      DropdownItem(value: 'KA', label: 'Karnataka'),
      DropdownItem(value: 'KL', label: 'Kerala'),
      DropdownItem(value: 'MP', label: 'Madhya Pradesh'),
      DropdownItem(value: 'MH', label: 'Maharashtra'),
      DropdownItem(value: 'MN', label: 'Manipur'),
      DropdownItem(value: 'ML', label: 'Meghalaya'),
      DropdownItem(value: 'MZ', label: 'Mizoram'),
      DropdownItem(value: 'NL', label: 'Nagaland'),
      DropdownItem(value: 'OR', label: 'Odisha'),
      DropdownItem(value: 'PB', label: 'Punjab'),
      DropdownItem(value: 'RJ', label: 'Rajasthan'),
      DropdownItem(value: 'SK', label: 'Sikkim'),
      DropdownItem(value: 'TN', label: 'Tamil Nadu'),
      DropdownItem(value: 'TG', label: 'Telangana'),
      DropdownItem(value: 'TR', label: 'Tripura'),
      DropdownItem(value: 'UP', label: 'Uttar Pradesh'),
      DropdownItem(value: 'UT', label: 'Uttarakhand'),
      DropdownItem(value: 'WB', label: 'West Bengal'),
    ],
  };

  static final Map<String, List<DropdownItem>> _citiesByCountry = {
    'US': [
      DropdownItem(value: 'New York', label: 'New York'),
      DropdownItem(value: 'Los Angeles', label: 'Los Angeles'),
      DropdownItem(value: 'Chicago', label: 'Chicago'),
      DropdownItem(value: 'Houston', label: 'Houston'),
      DropdownItem(value: 'Phoenix', label: 'Phoenix'),
      DropdownItem(value: 'Philadelphia', label: 'Philadelphia'),
      DropdownItem(value: 'San Antonio', label: 'San Antonio'),
      DropdownItem(value: 'San Diego', label: 'San Diego'),
      DropdownItem(value: 'Dallas', label: 'Dallas'),
      DropdownItem(value: 'San Jose', label: 'San Jose'),
      DropdownItem(value: 'Austin', label: 'Austin'),
      DropdownItem(value: 'Jacksonville', label: 'Jacksonville'),
      DropdownItem(value: 'Fort Worth', label: 'Fort Worth'),
      DropdownItem(value: 'Columbus', label: 'Columbus'),
      DropdownItem(value: 'Charlotte', label: 'Charlotte'),
      DropdownItem(value: 'San Francisco', label: 'San Francisco'),
      DropdownItem(value: 'Indianapolis', label: 'Indianapolis'),
      DropdownItem(value: 'Seattle', label: 'Seattle'),
      DropdownItem(value: 'Denver', label: 'Denver'),
      DropdownItem(value: 'Washington', label: 'Washington'),
      DropdownItem(value: 'Boston', label: 'Boston'),
      DropdownItem(value: 'El Paso', label: 'El Paso'),
      DropdownItem(value: 'Nashville', label: 'Nashville'),
      DropdownItem(value: 'Detroit', label: 'Detroit'),
      DropdownItem(value: 'Oklahoma City', label: 'Oklahoma City'),
      DropdownItem(value: 'Portland', label: 'Portland'),
      DropdownItem(value: 'Las Vegas', label: 'Las Vegas'),
      DropdownItem(value: 'Memphis', label: 'Memphis'),
      DropdownItem(value: 'Louisville', label: 'Louisville'),
      DropdownItem(value: 'Baltimore', label: 'Baltimore'),
      DropdownItem(value: 'Milwaukee', label: 'Milwaukee'),
      DropdownItem(value: 'Albuquerque', label: 'Albuquerque'),
      DropdownItem(value: 'Tucson', label: 'Tucson'),
      DropdownItem(value: 'Fresno', label: 'Fresno'),
      DropdownItem(value: 'Sacramento', label: 'Sacramento'),
      DropdownItem(value: 'Kansas City', label: 'Kansas City'),
      DropdownItem(value: 'Mesa', label: 'Mesa'),
      DropdownItem(value: 'Atlanta', label: 'Atlanta'),
      DropdownItem(value: 'Colorado Springs', label: 'Colorado Springs'),
      DropdownItem(value: 'Raleigh', label: 'Raleigh'),
      DropdownItem(value: 'Omaha', label: 'Omaha'),
      DropdownItem(value: 'Miami', label: 'Miami'),
      DropdownItem(value: 'Long Beach', label: 'Long Beach'),
      DropdownItem(value: 'Virginia Beach', label: 'Virginia Beach'),
      DropdownItem(value: 'Oakland', label: 'Oakland'),
      DropdownItem(value: 'Minneapolis', label: 'Minneapolis'),
      DropdownItem(value: 'Tulsa', label: 'Tulsa'),
      DropdownItem(value: 'Tampa', label: 'Tampa'),
      DropdownItem(value: 'Arlington', label: 'Arlington'),
      DropdownItem(value: 'New Orleans', label: 'New Orleans'),
    ],
    'CA': [
      DropdownItem(value: 'Toronto', label: 'Toronto'),
      DropdownItem(value: 'Montreal', label: 'Montreal'),
      DropdownItem(value: 'Vancouver', label: 'Vancouver'),
      DropdownItem(value: 'Calgary', label: 'Calgary'),
      DropdownItem(value: 'Edmonton', label: 'Edmonton'),
      DropdownItem(value: 'Ottawa', label: 'Ottawa'),
      DropdownItem(value: 'Winnipeg', label: 'Winnipeg'),
      DropdownItem(value: 'Quebec City', label: 'Quebec City'),
      DropdownItem(value: 'Hamilton', label: 'Hamilton'),
      DropdownItem(value: 'Kitchener', label: 'Kitchener'),
      DropdownItem(value: 'London', label: 'London'),
      DropdownItem(value: 'Victoria', label: 'Victoria'),
      DropdownItem(value: 'Halifax', label: 'Halifax'),
      DropdownItem(value: 'Oshawa', label: 'Oshawa'),
      DropdownItem(value: 'Windsor', label: 'Windsor'),
    ],
    'GB': [
      DropdownItem(value: 'London', label: 'London'),
      DropdownItem(value: 'Birmingham', label: 'Birmingham'),
      DropdownItem(value: 'Manchester', label: 'Manchester'),
      DropdownItem(value: 'Glasgow', label: 'Glasgow'),
      DropdownItem(value: 'Liverpool', label: 'Liverpool'),
      DropdownItem(value: 'Edinburgh', label: 'Edinburgh'),
      DropdownItem(value: 'Leeds', label: 'Leeds'),
      DropdownItem(value: 'Sheffield', label: 'Sheffield'),
      DropdownItem(value: 'Bristol', label: 'Bristol'),
      DropdownItem(value: 'Cardiff', label: 'Cardiff'),
      DropdownItem(value: 'Belfast', label: 'Belfast'),
      DropdownItem(value: 'Newcastle', label: 'Newcastle'),
      DropdownItem(value: 'Nottingham', label: 'Nottingham'),
      DropdownItem(value: 'Leicester', label: 'Leicester'),
    ],
    'AU': [
      DropdownItem(value: 'Sydney', label: 'Sydney'),
      DropdownItem(value: 'Melbourne', label: 'Melbourne'),
      DropdownItem(value: 'Brisbane', label: 'Brisbane'),
      DropdownItem(value: 'Perth', label: 'Perth'),
      DropdownItem(value: 'Adelaide', label: 'Adelaide'),
      DropdownItem(value: 'Gold Coast', label: 'Gold Coast'),
      DropdownItem(value: 'Newcastle', label: 'Newcastle'),
      DropdownItem(value: 'Canberra', label: 'Canberra'),
      DropdownItem(value: 'Sunshine Coast', label: 'Sunshine Coast'),
      DropdownItem(value: 'Wollongong', label: 'Wollongong'),
      DropdownItem(value: 'Hobart', label: 'Hobart'),
      DropdownItem(value: 'Geelong', label: 'Geelong'),
      DropdownItem(value: 'Townsville', label: 'Townsville'),
      DropdownItem(value: 'Cairns', label: 'Cairns'),
    ],
    'IN': [
      DropdownItem(value: 'Mumbai', label: 'Mumbai'),
      DropdownItem(value: 'Delhi', label: 'Delhi'),
      DropdownItem(value: 'Bangalore', label: 'Bangalore'),
      DropdownItem(value: 'Hyderabad', label: 'Hyderabad'),
      DropdownItem(value: 'Chennai', label: 'Chennai'),
      DropdownItem(value: 'Kolkata', label: 'Kolkata'),
      DropdownItem(value: 'Pune', label: 'Pune'),
      DropdownItem(value: 'Ahmedabad', label: 'Ahmedabad'),
      DropdownItem(value: 'Jaipur', label: 'Jaipur'),
      DropdownItem(value: 'Surat', label: 'Surat'),
      DropdownItem(value: 'Lucknow', label: 'Lucknow'),
      DropdownItem(value: 'Kanpur', label: 'Kanpur'),
      DropdownItem(value: 'Nagpur', label: 'Nagpur'),
      DropdownItem(value: 'Indore', label: 'Indore'),
      DropdownItem(value: 'Thane', label: 'Thane'),
      DropdownItem(value: 'Bhopal', label: 'Bhopal'),
      DropdownItem(value: 'Visakhapatnam', label: 'Visakhapatnam'),
      DropdownItem(value: 'Pimpri-Chinchwad', label: 'Pimpri-Chinchwad'),
      DropdownItem(value: 'Patna', label: 'Patna'),
      DropdownItem(value: 'Vadodara', label: 'Vadodara'),
    ],
  };

  // Dynamic lists that change based on selected country
  List<DropdownItem> get _availableStates {
    final states = _statesByCountry[_selectedCountry];
    if (states != null && states.isNotEmpty) {
      return states;
    }
    // For countries without predefined states, allow custom input
    return [DropdownItem(value: 'Other', label: 'Other (Enter manually)')];
  }

  List<DropdownItem> get _availableCities {
    final cities = _citiesByCountry[_selectedCountry];
    if (cities != null && cities.isNotEmpty) {
      return cities;
    }
    // For countries without predefined cities, allow custom input
    return [DropdownItem(value: 'Other', label: 'Other (Enter manually)')];
  }

  // Countries list
  final List<DropdownItem> _countries = [
    DropdownItem(value: 'US', label: 'United States', icon: '🇺🇸'),
    DropdownItem(value: 'CA', label: 'Canada', icon: '🇨🇦'),
    DropdownItem(value: 'GB', label: 'United Kingdom', icon: '🇬🇧'),
    DropdownItem(value: 'AU', label: 'Australia', icon: '🇦🇺'),
    DropdownItem(value: 'DE', label: 'Germany', icon: '🇩🇪'),
    DropdownItem(value: 'FR', label: 'France', icon: '🇫🇷'),
    DropdownItem(value: 'IN', label: 'India', icon: '🇮🇳'),
    DropdownItem(value: 'JP', label: 'Japan', icon: '🇯🇵'),
    DropdownItem(value: 'BR', label: 'Brazil', icon: '🇧🇷'),
    DropdownItem(value: 'MX', label: 'Mexico', icon: '🇲🇽'),
    DropdownItem(value: 'IT', label: 'Italy', icon: '🇮🇹'),
    DropdownItem(value: 'ES', label: 'Spain', icon: '🇪🇸'),
    DropdownItem(value: 'NL', label: 'Netherlands', icon: '🇳🇱'),
    DropdownItem(value: 'SE', label: 'Sweden', icon: '🇸🇪'),
    DropdownItem(value: 'NO', label: 'Norway', icon: '🇳🇴'),
  ];

  String get _zipCodeLabel {
    switch (_selectedCountry) {
      case 'US':
        return 'ZIP Code';
      case 'CA':
        return 'Postal Code';
      case 'GB':
        return 'Postcode';
      case 'AU':
        return 'Postcode';
      default:
        return 'Postal Code';
    }
  }

  String get _zipCodeHint {
    switch (_selectedCountry) {
      case 'US':
        return 'Enter ZIP code';
      case 'CA':
        return 'Enter postal code (e.g., K1A 0A6)';
      case 'GB':
        return 'Enter postcode (e.g., SW1A 1AA)';
      case 'AU':
        return 'Enter postcode (e.g., 2000)';
      default:
        return 'Enter postal code';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAddressData();
    _addListeners();
  }

  @override
  void dispose() {
    _removeListeners();
    _streetController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _addListeners() {
    _streetController.addListener(_onFieldChanged);
    _zipCodeController.addListener(_onFieldChanged);
  }

  void _removeListeners() {
    _streetController.removeListener(_onFieldChanged);
    _zipCodeController.removeListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final currentData = {
      'address': _streetController.text.trim(),
      'city': _selectedCity ?? '',
      'state': _selectedState ?? '',
      'zipCode': _zipCodeController.text.trim(),
      'country': _selectedCountry ?? '',
    };

    final hasChanges = !_mapsEqual(currentData, _originalData);
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (String key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  Future<void> _loadAddressData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName =
            role == 'employer' ? 'employers' : 'users_specific';

        final doc =
            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(user.uid)
                .get();

        if (doc.exists && mounted) {
          final userData = doc.data() ?? {};
          setState(() {
            _streetController.text = userData['address'] ?? '';
            _selectedCity =
                userData['city']?.isEmpty == true ? null : userData['city'];
            _selectedState =
                userData['state']?.isEmpty == true ? null : userData['state'];
            _zipCodeController.text = userData['zipCode'] ?? '';
            _selectedCountry =
                userData['country']?.isEmpty == true
                    ? null
                    : (userData['country'] ?? 'US');

            _originalData = {
              'address': _streetController.text.trim(),
              'city': _selectedCity ?? '',
              'state': _selectedState ?? '',
              'zipCode': _zipCodeController.text.trim(),
              'country': _selectedCountry ?? '',
            };

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error loading address: $e');
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_validateFields()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName =
            role == 'employer' ? 'employers' : 'users_specific';

        final addressData = {
          'address': _streetController.text.trim(),
          'city': _selectedCity ?? '',
          'state': _selectedState ?? '',
          'zipCode': _zipCodeController.text.trim(),
          'country': _selectedCountry ?? 'US',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid)
            .update(addressData);

        // Update profile completion status
        AuthService.updateProfileCompletionStatus();

        if (mounted) {
          _showSuccessSnackBar('Address updated successfully!');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error saving address: $e');
      }
    }
  }

  bool _validateFields() {
    if (_streetController.text.trim().isEmpty) {
      _showErrorSnackBar('Street address is required');
      return false;
    }
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      _showErrorSnackBar('City is required');
      return false;
    }
    if (_selectedState == null || _selectedState!.isEmpty) {
      final stateLabel =
          _selectedCountry == 'CA'
              ? 'Province'
              : _selectedCountry == 'GB'
              ? 'Region'
              : _selectedCountry == 'AU'
              ? 'State/Territory'
              : 'State';
      _showErrorSnackBar('$stateLabel is required');
      return false;
    }
    if (_zipCodeController.text.trim().isEmpty) {
      _showErrorSnackBar('$_zipCodeLabel is required');
      return false;
    }
    return true;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: AppColors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _handleBackNavigation() async {
    if (_hasUnsavedChanges) {
      final shouldPop = await _showUndoModal();
      if (shouldPop == true && mounted) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  Future<bool?> _showUndoModal() async {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _buildUndoModal(),
    );
  }

  Widget _buildUndoModal() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF5B5858),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 55),
            const Text(
              'Undo Changes ?',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.302,
                color: Color(0xFF150B3D),
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 44),
              child: Text(
                'Are you sure you want to change what you entered?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  height: 1.302,
                  color: Color(0xFF524B6B),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(height: 56),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 29),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      width: 317,
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
                          'CONTINUE FILLING',
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _hasUnsavedChanges = false;
                      });
                      Navigator.pop(context, true);
                    },
                    child: Container(
                      width: 317,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6CDFE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          'UNDO CHANGES',
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
            SizedBox(height: 72 + bottomPadding), // Custom nav bar + system padding
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gigAppPurple),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                // Header with back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _handleBackNavigation,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            Icons.arrow_back,
                            color: Color(0xFF3B4657),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Address form section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Edit Address',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.302,
                          color: Color(0xFF150B3D),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Street Address field
                      _buildTextField(
                        controller: _streetController,
                        label: 'Street Address',
                        hintText: 'Enter your street address',
                        prefixIcon: Icons.home_rounded,
                      ),

                      const SizedBox(height: 16),

                      // City dropdown
                      CustomDropdownField(
                        labelText: 'City',
                        hintText: 'Select your city',
                        value:
                            _availableCities.any(
                                  (city) => city.value == _selectedCity,
                                )
                                ? _selectedCity
                                : null,
                        items: _availableCities,
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                          _onFieldChanged();
                        },
                        enableSearch: true,
                        prefixIcon: Icons.location_city_rounded,
                        modalTitle: 'Select City',
                      ),

                      const SizedBox(height: 16),

                      // State dropdown
                      CustomDropdownField(
                        labelText:
                            _selectedCountry == 'CA'
                                ? 'Province'
                                : _selectedCountry == 'GB'
                                ? 'Region'
                                : _selectedCountry == 'AU'
                                ? 'State/Territory'
                                : 'State',
                        hintText:
                            _selectedCountry == 'CA'
                                ? 'Select your province'
                                : _selectedCountry == 'GB'
                                ? 'Select your region'
                                : _selectedCountry == 'AU'
                                ? 'Select your state/territory'
                                : 'Select your state',
                        value:
                            _availableStates.any(
                                  (state) => state.value == _selectedState,
                                )
                                ? _selectedState
                                : null,
                        items: _availableStates,
                        onChanged: (value) {
                          setState(() {
                            _selectedState = value;
                          });
                          _onFieldChanged();
                        },
                        enableSearch: true,
                        prefixIcon: Icons.map_rounded,
                        modalTitle:
                            _selectedCountry == 'CA'
                                ? 'Select Province'
                                : _selectedCountry == 'GB'
                                ? 'Select Region'
                                : _selectedCountry == 'AU'
                                ? 'Select State/Territory'
                                : 'Select State',
                      ),

                      const SizedBox(height: 16),

                      // ZIP Code field
                      _buildTextField(
                        controller: _zipCodeController,
                        label: _zipCodeLabel,
                        hintText: _zipCodeHint,
                        prefixIcon: Icons.local_post_office_rounded,
                        keyboardType:
                            _selectedCountry == 'CA' || _selectedCountry == 'GB'
                                ? TextInputType.text
                                : TextInputType.number,
                      ),

                      const SizedBox(height: 16),

                      // Country dropdown
                      CustomDropdownField(
                        labelText: 'Country',
                        hintText: 'Select your country',
                        value: _selectedCountry,
                        items: _countries,
                        onChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                            // Clear city and state when country changes
                            _selectedCity = null;
                            _selectedState = null;
                          });
                          _onFieldChanged();
                        },
                        enableSearch: true,
                        prefixIcon: Icons.public_rounded,
                        modalTitle: 'Select Country',
                      ),

                      const SizedBox(height: 32),

                      // Save button
                      Center(
                        child: GestureDetector(
                          onTap: _isSaving ? null : _saveAddress,
                          child: Container(
                            width: 213,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF130160),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF99ABC6,
                                  ).withOpacity(0.18),
                                  blurRadius: 62,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child:
                                  _isSaving
                                      ? const CircularProgressIndicator(
                                        color: AppColors.white,
                                        strokeWidth: 2,
                                      )
                                      : const Text(
                                        'SAVE',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          height: 1.302,
                                          letterSpacing: 0.84,
                                          color: AppColors.white,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF150B3D),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF99ABC6).withOpacity(0.18),
                blurRadius: 62,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 1.302,
              color: Color(0xFF150B3D),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                height: 1.302,
                color: Color(0xFFAAA6B9),
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: const Color(0xFF2F51A7),
                size: 20,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
