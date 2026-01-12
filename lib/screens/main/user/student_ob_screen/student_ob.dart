import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/routes/routes.dart';
import 'package:get_work_app/screens/main/employer/emp_ob/cd_servi.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/services/pdf_service.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/error_handler.dart';
import 'package:get_work_app/widgets/custom_dropdown_field.dart';
import 'package:get_work_app/widgets/phone_input_field.dart';
import 'package:image_picker/image_picker.dart';

import 'skills_list.dart';

// Enhanced validation result class
class ValidationResult {
  final bool isValid;
  final int? pageWithError;
  final String? fieldName;
  final String? errorMessage;
  final FocusNode? focusNode;

  ValidationResult({
    required this.isValid,
    this.pageWithError,
    this.fieldName,
    this.errorMessage,
    this.focusNode,
  });

  // Helper constructor for valid result
  ValidationResult.valid() : this(isValid: true);

  // Helper constructor for invalid result
  ValidationResult.invalid({
    required int pageWithError,
    required String fieldName,
    required String errorMessage,
    FocusNode? focusNode,
  }) : this(
          isValid: false,
          pageWithError: pageWithError,
          fieldName: fieldName,
          errorMessage: errorMessage,
          focusNode: focusNode,
        );
}

// Field hint widget for helpful tooltips
class FieldHintWidget extends StatelessWidget {
  final String hint;
  final IconData icon;
  final Color? color;

  const FieldHintWidget({
    super.key,
    required this.hint,
    this.icon = Icons.info_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? AppColors.gigAppPurple).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? AppColors.gigAppPurple).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? AppColors.gigAppPurple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 12,
                color: color ?? AppColors.gigAppPurple,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentOnboardingScreen extends StatefulWidget {
  const StudentOnboardingScreen({super.key});

  @override
  State<StudentOnboardingScreen> createState() =>
      _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends State<StudentOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form controllers
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  
  // Address dropdown selections
  String? _selectedCity;
  String? _selectedState;
  String? _selectedCountry = 'US'; // Default to US
  final _bioController = TextEditingController();
  final _collegeController = TextEditingController();
  final _ageController = TextEditingController();
  final _customEducationController = TextEditingController();
  final _skillsSearchController = TextEditingController();

  String _selectedGender = '';
  String _selectedEducationLevel = '';
  DateTime? _selectedDateOfBirth;
  String _selectedCountryCode = '+91'; // Default to India

  // New fields for student model
  final List<String> _selectedSkills = [];
  List<String> _filteredSkills = [];
  int _weeklyHours = 10;
  final List<String> _selectedTimeSlots = [];
  File? _resumeFile;
  String? _resumeFileName;
  String? _resumePreviewUrl;
  String? _resumeUrl; // Store the main PDF URL
  File? _profileImage;
  bool _isUploadingResume = false;
  final bool _isUploadingImage = false;

  // Visual enhancement fields
  final Map<int, bool> _pageCompletionStatus = {};
  String? _highlightedFieldError;

  // Address dropdown data
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
      DropdownItem(value: 'JH', label: 'Jharkhand'),
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
      DropdownItem(value: 'AN', label: 'Andaman and Nicobar Islands'),
      DropdownItem(value: 'CH', label: 'Chandigarh'),
      DropdownItem(value: 'DN', label: 'Dadra and Nagar Haveli and Daman and Diu'),
      DropdownItem(value: 'JK', label: 'Jammu and Kashmir'),
      DropdownItem(value: 'LA', label: 'Ladakh'),
      DropdownItem(value: 'LD', label: 'Lakshadweep'),
      DropdownItem(value: 'PY', label: 'Puducherry'),
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
      DropdownItem(value: 'Ghaziabad', label: 'Ghaziabad'),
      DropdownItem(value: 'Ludhiana', label: 'Ludhiana'),
      DropdownItem(value: 'Agra', label: 'Agra'),
      DropdownItem(value: 'Nashik', label: 'Nashik'),
      DropdownItem(value: 'Faridabad', label: 'Faridabad'),
      DropdownItem(value: 'Meerut', label: 'Meerut'),
      DropdownItem(value: 'Rajkot', label: 'Rajkot'),
      DropdownItem(value: 'Kalyan-Dombivali', label: 'Kalyan-Dombivali'),
      DropdownItem(value: 'Vasai-Virar', label: 'Vasai-Virar'),
      DropdownItem(value: 'Varanasi', label: 'Varanasi'),
      DropdownItem(value: 'Srinagar', label: 'Srinagar'),
      DropdownItem(value: 'Aurangabad', label: 'Aurangabad'),
      DropdownItem(value: 'Dhanbad', label: 'Dhanbad'),
      DropdownItem(value: 'Amritsar', label: 'Amritsar'),
      DropdownItem(value: 'Navi Mumbai', label: 'Navi Mumbai'),
      DropdownItem(value: 'Allahabad', label: 'Allahabad'),
      DropdownItem(value: 'Ranchi', label: 'Ranchi'),
      DropdownItem(value: 'Howrah', label: 'Howrah'),
      DropdownItem(value: 'Coimbatore', label: 'Coimbatore'),
      DropdownItem(value: 'Jabalpur', label: 'Jabalpur'),
      DropdownItem(value: 'Gwalior', label: 'Gwalior'),
      DropdownItem(value: 'Vijayawada', label: 'Vijayawada'),
      DropdownItem(value: 'Jodhpur', label: 'Jodhpur'),
      DropdownItem(value: 'Madurai', label: 'Madurai'),
      DropdownItem(value: 'Raipur', label: 'Raipur'),
      DropdownItem(value: 'Kota', label: 'Kota'),
      DropdownItem(value: 'Chandigarh', label: 'Chandigarh'),
      DropdownItem(value: 'Guwahati', label: 'Guwahati'),
      DropdownItem(value: 'Solapur', label: 'Solapur'),
      DropdownItem(value: 'Hubli-Dharwad', label: 'Hubli-Dharwad'),
      DropdownItem(value: 'Tiruchirappalli', label: 'Tiruchirappalli'),
      DropdownItem(value: 'Bareilly', label: 'Bareilly'),
    ],
  };

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

  // Dynamic lists that change based on selected country
  List<DropdownItem> get _availableStates {
    print('🔍 DEBUG: Getting states for country: $_selectedCountry');
    print('🔍 DEBUG: Available countries in states map: ${_statesByCountry.keys.toList()}');
    final states = _statesByCountry[_selectedCountry];
    print('🔍 DEBUG: Found states: ${states?.length ?? 0}');
    if (states != null && states.isNotEmpty) {
      return states;
    }
    return [DropdownItem(value: 'Other', label: 'Other (Enter manually)')];
  }

  List<DropdownItem> get _availableCities {
    print('🔍 DEBUG: Getting cities for country: $_selectedCountry');
    print('🔍 DEBUG: Available countries in cities map: ${_citiesByCountry.keys.toList()}');
    final cities = _citiesByCountry[_selectedCountry];
    print('🔍 DEBUG: Found cities: ${cities?.length ?? 0}');
    if (cities != null && cities.isNotEmpty) {
      return cities;
    }
    return [DropdownItem(value: 'Other', label: 'Other (Enter manually)')];
  }
  final Map<String, String> _fieldHints = {};
  final Map<String, bool> _fieldValidationStatus = {};

  // Enhanced education level options
  final List<DropdownItem> _educationLevels = [
    DropdownItem(value: 'High School Diploma', label: 'High School Diploma'),
    DropdownItem(value: 'High School (In Progress)', label: 'High School (In Progress)'),
    DropdownItem(value: 'Associate Degree', label: 'Associate Degree'),
    DropdownItem(value: 'Bachelor\'s Degree', label: 'Bachelor\'s Degree'),
    DropdownItem(value: 'Bachelor\'s Degree (In Progress)', label: 'Bachelor\'s Degree (In Progress)'),
    DropdownItem(value: 'Master\'s Degree', label: 'Master\'s Degree'),
    DropdownItem(value: 'Master\'s Degree (In Progress)', label: 'Master\'s Degree (In Progress)'),
    DropdownItem(value: 'PhD', label: 'PhD'),
    DropdownItem(value: 'PhD (In Progress)', label: 'PhD (In Progress)'),
    DropdownItem(value: 'Professional Certificate', label: 'Professional Certificate'),
    DropdownItem(value: 'Trade School', label: 'Trade School'),
    DropdownItem(value: 'Bootcamp Graduate', label: 'Bootcamp Graduate'),
    DropdownItem(value: 'Self-Taught', label: 'Self-Taught'),
    DropdownItem(value: 'Other', label: 'Other'),
  ];

  // All skills flattened for search

  // Time slots options
  final List<String> _availableTimeSlots = [
    'Early Morning (5AM - 8AM)',
    'Morning (8AM - 12PM)',
    'Afternoon (12PM - 5PM)',
    'Evening (5PM - 9PM)',
    'Night (9PM - 12AM)',
    'Late Night (12AM - 5AM)',
    'Weekdays Only',
    'Weekends Only',
    'Flexible Schedule',
  ];

  @override
  void initState() {
    super.initState();
    _filteredSkills = [];
    _updatePageCompletionStatus();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _bioController.dispose();
    _collegeController.dispose();
    _ageController.dispose();
    _customEducationController.dispose();
    _skillsSearchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _filterSkills(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSkills = [];
      } else {
        final queryLower = query.toLowerCase();
        _filteredSkills =
            allSkills
                .where(
                  (skill) =>
                      (skill.toLowerCase().contains(queryLower) ||
                          skill
                              .toLowerCase()
                              .split(' ')
                              .any((word) => word.startsWith(queryLower))) &&
                      !_selectedSkills.contains(skill),
                )
                .take(10)
                .toList();
      }
    });
  }

  /// Add custom skill when not found in predefined list
  void _addCustomSkill(String skillName) {
    final trimmed = skillName.trim();
    
    // Validate: min 2 characters, max 50 characters, not already selected
    if (trimmed.length >= 2 && 
        trimmed.length <= 50 && 
        !_selectedSkills.any((s) => s.toLowerCase() == trimmed.toLowerCase())) {
      setState(() {
        // Capitalize first letter of each word for consistency
        final capitalized = trimmed.split(' ')
            .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
        
        _selectedSkills.add(capitalized);
        _skillsSearchController.clear();
        _filterSkills('');
      });
      
      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "$trimmed" as custom skill'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.gigAppPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        // Calculate age from date of birth
        int age = DateTime.now().year - picked.year;
        if (DateTime.now().month < picked.month ||
            (DateTime.now().month == picked.month &&
                DateTime.now().day < picked.day)) {
          age--;
        }
        _ageController.text = age.toString();
      });
    }
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImageFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImageFromSource(ImageSource.camera);
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _profileImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImageFromSource(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _pickResume() async {
    print('🚀 [RESUME UPLOAD] Starting resume upload process...');
    
    try {
      print('📁 [RESUME UPLOAD] Opening file picker...');
      
      // Use file_picker for mobile compatibility
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        print('✅ [RESUME UPLOAD] File selected successfully');
        
        setState(() {
          _isUploadingResume = true;
        });

        final filePath = result.files.single.path!;
        final tempFile = File(filePath);
        final fileName = result.files.single.name;
        final fileSize = result.files.single.size;

        print('📄 [RESUME UPLOAD] File details:');
        print('   Name: $fileName');
        print('   Path: $filePath');
        print('   Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

        // Verify file exists
        print('🔍 [RESUME UPLOAD] Verifying file exists...');
        if (!await tempFile.exists()) {
          print('❌ [RESUME UPLOAD] File not found at path: $filePath');
          throw Exception('Selected file not found at path: $filePath');
        }
        print('✅ [RESUME UPLOAD] File exists and is accessible');

        // Validate file size (max 10MB)
        if (fileSize > 10 * 1024 * 1024) {
          print('❌ [RESUME UPLOAD] File too large: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
          throw Exception('File size too large. Please select a PDF under 10MB.');
        }

        // Validate file extension
        if (!fileName.toLowerCase().endsWith('.pdf')) {
          print('❌ [RESUME UPLOAD] Invalid file type: $fileName');
          throw Exception('Please select a PDF file only.');
        }

        print('📤 [RESUME UPLOAD] Starting upload to Cloudinary...');
        
        // Use PDFService to handle the upload
        final uploadResult = await PDFService.uploadResumePDF(tempFile);

        print('📊 [RESUME UPLOAD] Upload result:');
        print('   PDF URL: ${uploadResult['pdfUrl'] ?? 'NULL'}');
        print('   Preview URL: ${uploadResult['previewUrl'] ?? 'NULL'}');

        if (uploadResult['pdfUrl'] != null) {
          print('🎉 [RESUME UPLOAD] Upload successful!');
          
          setState(() {
            _resumeFile = tempFile;
            _resumeFileName = fileName;
            _resumeUrl = uploadResult['pdfUrl']; // Store main PDF URL
            _resumePreviewUrl = uploadResult['previewUrl'];
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Resume uploaded successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: 100, left: 16, right: 16),
              ),
            );
          }
        } else {
          print('❌ [RESUME UPLOAD] Upload failed - no PDF URL returned');
          throw Exception('Failed to upload resume to server. Please check your internet connection and try again.');
        }
      } else {
        print('ℹ️ [RESUME UPLOAD] User cancelled file selection');
        // User cancelled the picker - this is not an error
        return;
      }
    } catch (e, stackTrace) {
      print('❌ [RESUME UPLOAD] Error occurred: $e');
      print('📍 [RESUME UPLOAD] Stack trace: $stackTrace');
      
      if (mounted) {
        String userMessage = 'Something went wrong. Please try again.';
        
        // Provide specific error messages based on error type
        final errorString = e.toString().toLowerCase();
        
        if (errorString.contains('file not found') || errorString.contains('not found')) {
          userMessage = 'Selected file could not be found. Please try selecting the file again.';
        } else if (errorString.contains('file size') || errorString.contains('too large')) {
          userMessage = 'File is too large. Please select a PDF under 10MB.';
        } else if (errorString.contains('pdf') && errorString.contains('only')) {
          userMessage = 'Please select a PDF file only.';
        } else if (errorString.contains('network') || errorString.contains('connection')) {
          userMessage = 'Network error. Please check your internet connection and try again.';
        } else if (errorString.contains('cloudinary') || errorString.contains('upload')) {
          userMessage = 'Upload service temporarily unavailable. Please try again in a few moments.';
        } else if (errorString.contains('permission') || errorString.contains('access')) {
          userMessage = 'Cannot access the selected file. Please try selecting a different file.';
        } else if (errorString.contains('timeout')) {
          userMessage = 'Upload timed out. Please check your internet connection and try again.';
        }
        
        print('👤 [RESUME UPLOAD] Showing user message: $userMessage');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                // Retry the upload
                _pickResume();
              },
            ),
          ),
        );
      }
    } finally {
      print('🏁 [RESUME UPLOAD] Cleaning up...');
      if (mounted) {
        setState(() {
          _isUploadingResume = false;
        });
      }
      print('✅ [RESUME UPLOAD] Process completed');
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      // Validate before moving to next page
      if (!_validateCurrentPage()) {
        return;
      }
      
      // Update completion status
      _updatePageCompletionStatus();
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Enhanced validation for current page (backward compatibility)
  bool _validateCurrentPage() {
    final result = _validateSpecificPage(_currentPage);
    if (!result.isValid) {
      _showValidationError(result);
      return false;
    }
    return true;
  }

  // Comprehensive validation for ALL pages
  ValidationResult _validateAllPages() {
    print('🔍 [VALIDATION] Starting comprehensive validation of all pages...');
    
    for (int page = 0; page <= 4; page++) {
      final result = _validateSpecificPage(page);
      if (!result.isValid) {
        print('❌ [VALIDATION] Found issue on page $page: ${result.errorMessage}');
        return result;
      }
    }
    
    print('✅ [VALIDATION] All pages validated successfully');
    return ValidationResult.valid();
  }

  // Validate a specific page and return detailed result
  ValidationResult _validateSpecificPage(int pageIndex) {
    switch (pageIndex) {
      case 0: // Personal Info
        // Validate phone number
        final phoneError = _validatePhone(_phoneController.text);
        if (phoneError != null) {
          return ValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Phone Number',
            errorMessage: phoneError,
            focusNode: FocusNode(),
          );
        }
        if (_selectedGender.isEmpty) {
          return ValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Gender',
            errorMessage: 'Please select your gender on Personal Info page',
          );
        }
        if (_selectedDateOfBirth == null) {
          return ValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Date of Birth',
            errorMessage: 'Date of birth is required on Personal Info page',
          );
        }
        // Validate age
        final ageError = _validateAge(_ageController.text);
        if (ageError != null) {
          return ValidationResult.invalid(
            pageWithError: 0,
            fieldName: 'Age',
            errorMessage: ageError,
            focusNode: FocusNode(),
          );
        }
        break;
        
      case 1: // Address
        if (_addressController.text.trim().isEmpty) {
          return ValidationResult.invalid(
            pageWithError: 1,
            fieldName: 'Address',
            errorMessage: 'Address is required on Address page',
            focusNode: FocusNode(),
          );
        }
        if (_selectedCity == null || _selectedCity!.isEmpty) {
          return ValidationResult.invalid(
            pageWithError: 1,
            fieldName: 'City',
            errorMessage: 'City is required on Address page',
            focusNode: FocusNode(),
          );
        }
        if (_selectedState == null || _selectedState!.isEmpty) {
          return ValidationResult.invalid(
            pageWithError: 1,
            fieldName: 'State',
            errorMessage: 'State is required on Address page',
            focusNode: FocusNode(),
          );
        }
        if (_zipController.text.trim().isEmpty) {
          return ValidationResult.invalid(
            pageWithError: 1,
            fieldName: 'ZIP Code',
            errorMessage: 'ZIP code is required on Address page',
            focusNode: FocusNode(),
          );
        }
        if (_selectedCountry == null || _selectedCountry!.isEmpty) {
          return ValidationResult.invalid(
            pageWithError: 1,
            fieldName: 'Country',
            errorMessage: 'Country is required on Address page',
            focusNode: FocusNode(),
          );
        }
        break;
        
      case 2: // Education
        if (_selectedEducationLevel.isEmpty) {
          return ValidationResult.invalid(
            pageWithError: 2,
            fieldName: 'Education Level',
            errorMessage: 'Please select your education level on Education page',
          );
        }
        if (_selectedEducationLevel == 'Other' && 
            _customEducationController.text.trim().isEmpty) {
          return ValidationResult.invalid(
            pageWithError: 2,
            fieldName: 'Custom Education',
            errorMessage: 'Please specify your education level on Education page',
            focusNode: FocusNode(),
          );
        }
        if (_collegeController.text.trim().isEmpty) {
          return ValidationResult.invalid(
            pageWithError: 2,
            fieldName: 'College/Institution',
            errorMessage: 'College or institution name is required on Education page',
            focusNode: FocusNode(),
          );
        }
        break;
        
      case 3: // Skills & Availability
        if (_selectedSkills.isEmpty) {
          return ValidationResult.invalid(
            pageWithError: 3,
            fieldName: 'Skills',
            errorMessage: 'Please select at least one skill on Skills & Availability page',
          );
        }
        if (_selectedTimeSlots.isEmpty) {
          return ValidationResult.invalid(
            pageWithError: 3,
            fieldName: 'Time Slots',
            errorMessage: 'Please select your preferred time slots on Skills & Availability page',
          );
        }
        break;
        
      case 4: // Profile & Resume
        if (_profileImage == null) {
          return ValidationResult.invalid(
            pageWithError: 4,
            fieldName: 'Profile Photo',
            errorMessage: 'Please upload your profile photo on Profile & Documents page',
          );
        }
        if (_resumeFile == null) {
          return ValidationResult.invalid(
            pageWithError: 4,
            fieldName: 'Resume',
            errorMessage: 'Please upload your resume on Profile & Documents page',
          );
        }
        break;
    }
    
    return ValidationResult.valid();
  }

  // Show validation error with enhanced messaging
  void _showValidationError(ValidationResult result) {
    if (result.isValid) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.errorMessage ?? 'Please complete all required fields'),
        backgroundColor: Colors.red,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    
    // Focus on field if it's a text field
    if (result.focusNode != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(result.focusNode!);
      });
    }
  }

  // Navigate to page with validation error
  void _navigateToPageWithError(ValidationResult result) {
    if (result.pageWithError == null) return;
    
    print('🧭 [NAVIGATION] Auto-navigating to page ${result.pageWithError} for field: ${result.fieldName}');
    
    // Set highlighted field for visual feedback
    setState(() {
      _highlightedFieldError = result.fieldName;
    });
    
    _pageController.animateToPage(
      result.pageWithError!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    
    // Focus on the field after navigation
    if (result.focusNode != null) {
      Future.delayed(const Duration(milliseconds: 600), () {
        FocusScope.of(context).requestFocus(result.focusNode!);
      });
    }
    
    // Clear highlight after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _highlightedFieldError = null;
        });
      }
    });
  }

  // Update page completion status
  void _updatePageCompletionStatus() {
    for (int page = 0; page <= 4; page++) {
      final result = _validateSpecificPage(page);
      _pageCompletionStatus[page] = result.isValid;
    }
    if (mounted) {
      setState(() {});
    }
  }

  // Get completion percentage
  double _getCompletionPercentage() {
    int completedPages = _pageCompletionStatus.values.where((completed) => completed).length;
    return completedPages / 5.0;
  }

  // Get page completion icon
  Widget _getPageCompletionIcon(int pageIndex) {
    final isCompleted = _pageCompletionStatus[pageIndex] ?? false;
    final isCurrentPage = pageIndex == _currentPage;
    
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted 
            ? Colors.green 
            : isCurrentPage 
                ? AppColors.gigAppPurple 
                : Colors.grey.withOpacity(0.3),
        border: Border.all(
          color: isCurrentPage ? AppColors.gigAppPurple : Colors.transparent,
          width: 2,
        ),
      ),
      child: Icon(
        isCompleted ? Icons.check : Icons.circle,
        size: 12,
        color: isCompleted || isCurrentPage ? Colors.white : Colors.grey,
      ),
    );
  }

  // Get field decoration with error highlighting
  InputDecoration _getFieldDecoration(String label, String fieldName, {String? hintText}) {
    final isHighlighted = _highlightedFieldError == fieldName;
    
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isHighlighted ? Colors.red : AppColors.grey.withOpacity(0.3),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isHighlighted ? Colors.red : AppColors.gigAppPurple,
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isHighlighted ? Colors.red : AppColors.grey.withOpacity(0.3),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: isHighlighted,
      fillColor: isHighlighted ? Colors.red.withOpacity(0.1) : null,
    );
  }

  // Get page title for progress indicators
  String _getPageTitle(int pageIndex) {
    switch (pageIndex) {
      case 0: return 'Personal';
      case 1: return 'Address';
      case 2: return 'Education';
      case 3: return 'Skills';
      case 4: return 'Resume';
      default: return 'Step ${pageIndex + 1}';
    }
  }

  // Smart field validators with helpful feedback
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove spaces and special characters for validation
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Get country-specific length requirements
    final countryLengths = _getCountryPhoneLengths(_selectedCountryCode);
    final minLength = countryLengths['min'] ?? 10;
    final maxLength = countryLengths['max'] ?? 10;
    
    // Check length based on country
    if (cleaned.length < minLength) {
      return 'Phone number must be at least $minLength digits';
    }
    if (cleaned.length > maxLength) {
      return 'Phone number must not exceed $maxLength digits';
    }
    
    // Country-specific format validation
    if (_selectedCountryCode == '+91' && cleaned.isNotEmpty) {
      // Indian mobile numbers must start with 6, 7, 8, or 9
      final firstDigit = cleaned[0];
      if (!['6', '7', '8', '9'].contains(firstDigit)) {
        return 'Indian mobile numbers must start with 6, 7, 8, or 9';
      }
    }
    
    return null; // Valid
  }
  
  // Helper method to get country-specific phone length requirements
  Map<String, int> _getCountryPhoneLengths(String countryCode) {
    // Country code to length mapping
    final Map<String, Map<String, int>> countryLengths = {
      '+91': {'min': 10, 'max': 10},  // India
      '+1': {'min': 10, 'max': 10},   // US/Canada
      '+44': {'min': 10, 'max': 10},  // UK
      '+61': {'min': 9, 'max': 9},    // Australia
      '+49': {'min': 10, 'max': 11},  // Germany
      '+33': {'min': 9, 'max': 9},    // France
      '+81': {'min': 10, 'max': 10},  // Japan
      '+86': {'min': 11, 'max': 11},  // China
      '+55': {'min': 10, 'max': 11},  // Brazil
      '+7': {'min': 10, 'max': 10},   // Russia
      '+82': {'min': 9, 'max': 10},   // South Korea
      '+52': {'min': 10, 'max': 10},  // Mexico
      '+39': {'min': 9, 'max': 10},   // Italy
      '+34': {'min': 9, 'max': 9},    // Spain
      '+31': {'min': 9, 'max': 9},    // Netherlands
      '+41': {'min': 9, 'max': 9},    // Switzerland
      '+46': {'min': 9, 'max': 10},   // Sweden
      '+65': {'min': 8, 'max': 8},    // Singapore
      '+971': {'min': 9, 'max': 9},   // UAE
      '+966': {'min': 9, 'max': 9},   // Saudi Arabia
      '+27': {'min': 9, 'max': 9},    // South Africa
      '+92': {'min': 10, 'max': 10},  // Pakistan
      '+880': {'min': 10, 'max': 10}, // Bangladesh
      '+94': {'min': 9, 'max': 9},    // Sri Lanka
      '+977': {'min': 10, 'max': 10}, // Nepal
      '+60': {'min': 9, 'max': 10},   // Malaysia
      '+62': {'min': 10, 'max': 12},  // Indonesia
      '+66': {'min': 9, 'max': 9},    // Thailand
      '+63': {'min': 10, 'max': 10},  // Philippines
      '+84': {'min': 9, 'max': 10},   // Vietnam
      '+90': {'min': 10, 'max': 10},  // Turkey
      '+48': {'min': 9, 'max': 9},    // Poland
      '+54': {'min': 10, 'max': 10},  // Argentina
      '+56': {'min': 9, 'max': 9},    // Chile
      '+57': {'min': 10, 'max': 10},  // Colombia
      '+20': {'min': 10, 'max': 10},  // Egypt
      '+234': {'min': 10, 'max': 10}, // Nigeria
      '+254': {'min': 9, 'max': 9},   // Kenya
      '+64': {'min': 9, 'max': 10},   // New Zealand
    };
    
    return countryLengths[countryCode] ?? {'min': 10, 'max': 10}; // Default to 10 if country not found
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null; // Valid
  }

  String? _validateZipCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ZIP code is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length < 5) {
      return 'ZIP code must be at least 5 digits';
    }
    return null; // Valid
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    if (age < 16) {
      return 'You must be at least 16 years old';
    }
    if (age > 100) {
      return 'Please enter a valid age';
    }
    return null; // Valid
  }

  // Get helpful hint for field
  Widget? _getFieldHint(String fieldName) {
    switch (fieldName) {
      case 'Phone Number':
        return const FieldHintWidget(
          hint: 'Enter your 10-digit mobile number (e.g., 9876543210)',
          icon: Icons.phone_outlined,
        );
      case 'Date of Birth':
        return const FieldHintWidget(
          hint: 'Select your date of birth to calculate your age automatically',
          icon: Icons.cake_outlined,
        );
      case 'ZIP Code':
        return const FieldHintWidget(
          hint: 'Enter your area PIN code (e.g., 110001)',
          icon: Icons.location_on_outlined,
        );
      case 'College/Institution':
        return const FieldHintWidget(
          hint: 'Enter your current college or institution name',
          icon: Icons.school_outlined,
        );
      case 'Skills':
        return const FieldHintWidget(
          hint: 'Select at least 3 skills that match your expertise',
          icon: Icons.star_outline,
          color: Color(0xFF2F51A7),
        );
      case 'Resume':
        return const FieldHintWidget(
          hint: 'Upload your resume in PDF format (max 10MB)',
          icon: Icons.upload_file_outlined,
          color: Colors.blue,
        );
      default:
        return null;
    }
  }

  // Show success feedback for completed fields
  Widget _getSuccessFeedback(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get field hint text for specific fields
  String? _getFieldHintText(String fieldName) {
    final hints = {
      'Phone Number': 'Enter your 10-digit mobile number',
      'Age': 'Must be 18 or older to register',
      'Address': 'Enter your complete residential address',
      'City': 'Enter the city where you currently live',
      'State': 'Enter your state or province',
      'ZIP Code': 'Enter your postal/ZIP code',
      'College/Institution': 'Enter your current or most recent educational institution',
      'Custom Education': 'Please specify your education level',
    };
    return hints[fieldName];
  }

  // Validate field in real-time
  bool _validateFieldRealTime(String fieldName, String value) {
    switch (fieldName) {
      case 'Phone Number':
        final cleaned = value.trim();
        // Get country-specific length requirements
        final countryLengths = _getCountryPhoneLengths(_selectedCountryCode);
        final minLength = countryLengths['min'] ?? 10;
        final maxLength = countryLengths['max'] ?? 10;
        
        // Check if length is within valid range and all digits
        bool isValid = cleaned.length >= minLength && 
                       cleaned.length <= maxLength && 
                       RegExp(r'^\d+$').hasMatch(cleaned);
        
        // Country-specific format validation
        if (isValid && _selectedCountryCode == '+91' && cleaned.isNotEmpty) {
          // Indian mobile numbers must start with 6, 7, 8, or 9
          final firstDigit = cleaned[0];
          isValid = ['6', '7', '8', '9'].contains(firstDigit);
        }
        
        _fieldValidationStatus[fieldName] = isValid;
        return isValid;
      case 'Age':
        final age = int.tryParse(value.trim());
        final isValid = age != null && age >= 18 && age <= 100;
        _fieldValidationStatus[fieldName] = isValid;
        return isValid;
      case 'ZIP Code':
        final isValid = value.trim().length >= 5 && RegExp(r'^\d+$').hasMatch(value.trim());
        _fieldValidationStatus[fieldName] = isValid;
        return isValid;
      default:
        final isValid = value.trim().isNotEmpty;
        _fieldValidationStatus[fieldName] = isValid;
        return isValid;
    }
  }

  // Get enhanced field decoration with hints and validation
  InputDecoration _getEnhancedFieldDecoration(String label, String fieldName, {String? hintText}) {
    final isHighlighted = _highlightedFieldError == fieldName;
    final fieldHint = _getFieldHintText(fieldName);
    final isValid = _fieldValidationStatus[fieldName];
    
    Color borderColor = AppColors.grey.withOpacity(0.3);
    Color? fillColor;
    Widget? suffixIcon;
    
    if (isHighlighted) {
      borderColor = Colors.red;
      fillColor = Colors.red.withOpacity(0.1);
    } else if (isValid == true) {
      borderColor = Colors.green;
      suffixIcon = const Icon(Icons.check_circle, color: Colors.green, size: 20);
    } else if (isValid == false) {
      borderColor = const Color(0xFF2F51A7);
      suffixIcon = const Icon(Icons.warning, color: Color(0xFF2F51A7), size: 20);
    }
    
    return InputDecoration(
      labelText: label,
      hintText: hintText ?? fieldHint,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isHighlighted ? Colors.red : AppColors.gigAppPurple,
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: fillColor != null,
      fillColor: fillColor,
      helperText: isValid == false ? _getValidationMessage(fieldName) : null,
      helperStyle: const TextStyle(color: Color(0xFF2F51A7), fontSize: 12),
    );
  }

  // Get validation message for fields
  String? _getValidationMessage(String fieldName) {
    switch (fieldName) {
      case 'Phone Number':
        // Get country-specific length requirements
        final countryLengths = _getCountryPhoneLengths(_selectedCountryCode);
        final minLength = countryLengths['min'] ?? 10;
        final maxLength = countryLengths['max'] ?? 10;
        
        if (minLength == maxLength) {
          // Exact length required
          if (_selectedCountryCode == '+91') {
            return 'Must be exactly $minLength digits and start with 6, 7, 8, or 9';
          }
          return 'Must be exactly $minLength digits';
        } else {
          // Range of lengths allowed
          return 'Must be between $minLength and $maxLength digits';
        }
      case 'Age':
        return 'Age must be between 18 and 100';
      case 'ZIP Code':
        return 'Please enter a valid ZIP code';
      default:
        return 'This field is required';
    }
  }

  // Create tooltip widget for complex fields
  Widget _buildTooltipField({
    required Widget child,
    required String tooltip,
    String? fieldName,
  }) {
    return Tooltip(
      message: tooltip,
      decoration: BoxDecoration(
        color: AppColors.gigAppPurple,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      child: child,
    );
  }

  // Create field with real-time validation
  Widget _buildValidatedTextField({
    required TextEditingController controller,
    required String label,
    required String fieldName,
    String? hintText,
    TextInputType? keyboardType,
    int? maxLines,
    String? tooltip,
  }) {
    Widget textField = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      decoration: _getEnhancedFieldDecoration(label, fieldName, hintText: hintText),
      onChanged: (value) {
        _validateFieldRealTime(fieldName, value);
        _updatePageCompletionStatus();
      },
    );

    if (tooltip != null) {
      textField = _buildTooltipField(
        child: textField,
        tooltip: tooltip,
        fieldName: fieldName,
      );
    }

    return textField;
  }

  // Build smart completion indicator for current page
  Widget _buildPageCompletionIndicator() {
    final currentPageValid = _pageCompletionStatus[_currentPage] ?? false;
    final completionPercentage = _getCompletionPercentage();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentPageValid ? Colors.green.withOpacity(0.1) : const Color(0xFF2F51A7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: currentPageValid ? Colors.green : const Color(0xFF2F51A7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            currentPageValid ? Icons.check_circle : Icons.info,
            color: currentPageValid ? Colors.green : const Color(0xFF2F51A7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              currentPageValid 
                  ? 'This page is complete! ${completionPercentage == 1.0 ? "Ready to finish!" : "Continue to next page."}'
                  : 'Please complete all required fields on this page',
              style: TextStyle(
                color: currentPageValid ? Colors.green : const Color(0xFF2F51A7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (completionPercentage > 0)
            Text(
              '${(completionPercentage * 100).toInt()}%',
              style: TextStyle(
                color: currentPageValid ? Colors.green : const Color(0xFF2F51A7),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  // Skip onboarding confirmation dialog
  Future<bool?> _showSkipConfirmation() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: const Text(
          'Skip Profile Setup?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.gigAppPurple,
            fontFamily: 'DM Sans',
          ),
        ),
        content: const Text(
          'You can complete your profile anytime from the Settings section. A complete profile helps you get better job matches!',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.gigAppDescriptionText,
            fontFamily: 'DM Sans',
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              // Go Back button with light purple background
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gigAppLightPurple,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'DM Sans',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Skip button with dark purple background
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gigAppPurple,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'DM Sans',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // Skip onboarding and go to home
  Future<void> _skipOnboarding() async {
    final confirmed = await _showSkipConfirmation();
    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Mark onboarding as skipped in Firestore
      await AuthService.skipOnboarding();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to user home screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.userHome,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _completeOnboarding() async {
    print('🎯 [ONBOARDING] Starting completion process...');
    
    // Comprehensive validation of ALL pages
    final validationResult = _validateAllPages();
    if (!validationResult.isValid) {
      print('❌ [ONBOARDING] Validation failed, navigating to problematic page');
      _showValidationError(validationResult);
      _navigateToPageWithError(validationResult);
      return;
    }
    
    // Additional validation for critical fields
    if (_phoneController.text.trim().isEmpty) {
      ErrorHandler.showErrorSnackBar(context, Exception('Phone number is required'));
      return;
    }
    
    if (_selectedGender.isEmpty) {
      ErrorHandler.showErrorSnackBar(context, Exception('Gender selection is required'));
      return;
    }
    
    if (_selectedDateOfBirth == null) {
      ErrorHandler.showErrorSnackBar(context, Exception('Date of birth is required'));
      return;
    }
    
    print('✅ [ONBOARDING] All validations passed, proceeding with completion');

    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Show progress indicator with steps
      _showProgressDialog();
      
      // Add timeout to prevent infinite loading
      await Future.any([
        _performOnboardingCompletion(),
        Future.delayed(const Duration(seconds: 30), () {
          throw Exception('Onboarding completion timed out. Please check your internet connection and try again.');
        }),
      ]);
      
      // Hide progress dialog on success
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ [ONBOARDING] Error during completion: $e');
      
      // Hide progress dialog on error
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _performOnboardingCompletion() async {
    try {
      print('📤 [ONBOARDING] Starting upload processes...');
      
      // Validate that we have all required data
      if (_selectedSkills.isEmpty) {
        throw Exception('Please select at least one skill before completing your profile');
      }
      
      // Upload profile image if selected
      String? profileImageUrl;
      if (_profileImage != null) {
        print('🖼️ [ONBOARDING] Uploading profile image...');
        profileImageUrl = await CloudinaryService.uploadImage(_profileImage!).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Profile image upload timed out');
          },
        );
        if (profileImageUrl == null) {
          throw Exception('Failed to upload profile image');
        }
        print('✅ [ONBOARDING] Profile image uploaded successfully');
      }

      // Use already uploaded resume URLs or upload if not done yet
      Map<String, String?> resumeUrls = {};
      if (_resumeFile != null) {
        if (_resumeUrl != null && _resumePreviewUrl != null) {
          // Resume already uploaded, use existing URLs
          print('✅ [ONBOARDING] Using already uploaded resume URLs');
          print('   PDF URL: $_resumeUrl');
          print('   Preview URL: $_resumePreviewUrl');
          resumeUrls = {
            'pdfUrl': _resumeUrl,
            'previewUrl': _resumePreviewUrl,
          };
        } else {
          // Resume not uploaded yet, upload now
          print('📤 [ONBOARDING] Resume not uploaded yet, uploading now...');
          resumeUrls = await PDFService.uploadResumePDF(_resumeFile!).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception('Resume upload timed out');
            },
          );
          if (resumeUrls['pdfUrl'] == null) {
            throw Exception('Failed to upload resume');
          }
          print('✅ [ONBOARDING] Resume uploaded successfully');
        }
      }

      // Prepare education level
      String finalEducationLevel = _selectedEducationLevel;
      if (_selectedEducationLevel == 'Other' &&
          _customEducationController.text.trim().isNotEmpty) {
        finalEducationLevel = _customEducationController.text.trim();
      }

      // Prepare onboarding data with student model structure
      Map<String, dynamic> onboardingData = {
        'phone': '$_selectedCountryCode ${_phoneController.text.trim()}',
        'phoneCountryCode': _selectedCountryCode,
        'phoneNumber': _phoneController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': _selectedDateOfBirth?.toIso8601String(),
        'address': _addressController.text.trim(),
        'city': _selectedCity ?? '',
        'state': _selectedState ?? '',
        'zipCode': _zipController.text.trim(),
        'country': _selectedCountry ?? 'US',
        'educationLevel': finalEducationLevel,
        'bio': _bioController.text.trim(),
        'onboardingCompleted': true,
        'onboardingCompletedAt': DateTime.now().toIso8601String(),

        // Student model specific fields
        'userType': 'student',
        'name': '', // This should be filled from user's display name
        'age': int.tryParse(_ageController.text.trim()) ?? 18,
        'college': _collegeController.text.trim(),
        'skills': _selectedSkills,
        'availability': {
          'weeklyHours': _weeklyHours,
          'preferredSlots': _selectedTimeSlots,
        },
        'totalEarned': 0.0,
        'upiLinked': false,
        'profileImageUrl': profileImageUrl,
        'resumeUrl': resumeUrls['pdfUrl'],
        'resumePreviewUrl': resumeUrls['previewUrl'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Save onboarding data to user profile
      print('💾 [ONBOARDING] Saving onboarding data to Firestore...');
      await AuthService.completeUserOnboarding(onboardingData).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Firestore save operation timed out');
        },
      );
      print('✅ [ONBOARDING] Onboarding data saved successfully');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile setup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to user home screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.userHome,
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ [ONBOARDING] Error in completion: $e');
      rethrow; // Re-throw to be caught by the main completion method
    }
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gigAppPurple),
            ),
            const SizedBox(height: 16),
            const Text(
              'Completing your profile...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'DM Sans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'DM Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: AppColors.gigAppPurple,
          secondary: AppColors.gigAppPurple,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.gigAppPurple,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header with progress and action buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Complete Your Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        // Skip button in top right
                        if (_currentPage < 4)
                          TextButton(
                            onPressed: _isLoading ? null : _skipOnboarding,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Step ${_currentPage + 1} of 5',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Progress indicator
                    LinearProgressIndicator(
                      value: (_currentPage + 1) / 5,
                      backgroundColor: AppColors.grey.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.gigAppPurple,
                      ),
                    ),
                  ],
                ),
              ),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    // Update completion status when page changes
                    _updatePageCompletionStatus();
                  },
                  children: [
                    _buildPersonalInfoPage(),
                    _buildAddressPage(),
                    _buildEducationPage(),
                    _buildSkillsAndAvailabilityPage(),
                    _buildProfileAndResumeUploadPage(),
                  ],
                ),
              ),

              // Bottom navigation buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Previous button (light purple from Figma: #D6CDFE)
                    if (_currentPage > 0)
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _previousPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gigAppLightPurple,
                              foregroundColor: AppColors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              shadowColor: const Color(0x2E99ABC6),
                            ),
                            child: const Text(
                              'PREVIOUS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.84,
                                fontFamily: 'DM Sans',
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 15),
                    
                    // Next/Complete button (dark purple from Figma: #130160)
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : _currentPage == 4
                                  ? (_profileImage != null && _resumeFile != null)
                                      ? _completeOnboarding
                                      : null // Disable if profile image or resume not uploaded
                                  : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gigAppPurple,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            shadowColor: const Color(0x2E99ABC6),
                            disabledBackgroundColor: AppColors.grey.withOpacity(0.3),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _currentPage == 4 ? 'COMPLETE' : 'NEXT',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.84,
                                    fontFamily: 'DM Sans',
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Helper message for page 4 when uploads are incomplete
              if (_currentPage == 4 && (_profileImage == null || _resumeFile == null))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF2F51A7),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _profileImage == null && _resumeFile == null
                              ? 'Please upload both profile photo and resume to complete'
                              : _profileImage == null
                                  ? 'Please upload your profile photo to complete'
                                  : 'Please upload your resume to complete',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2F51A7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Handle skip onboarding
  Future<void> _handleSkipOnboarding() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          title: const Text(
            'Skip Profile Setup?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.gigAppPurple,
              fontFamily: 'DM Sans',
            ),
          ),
          content: const Text(
            'You can complete your profile anytime from the Settings section. A complete profile helps you get better job matches!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gigAppDescriptionText,
              fontFamily: 'DM Sans',
              height: 1.5,
            ),
          ),
          actions: [
            Row(
              children: [
                // Go Back button with light purple background
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gigAppLightPurple,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Go Back',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DM Sans',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Skip button with dark purple background
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gigAppPurple,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DM Sans',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );

      if (confirmed == true && mounted) {
        setState(() {
          _isLoading = true;
        });

        print('⏭️ [ONBOARDING] User chose to skip onboarding');
        
        // Call skipOnboarding method
        await AuthService.skipOnboarding();
        
        print('✅ [ONBOARDING] Skip onboarding completed');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Navigate to home
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('❌ [ONBOARDING] Error skipping onboarding: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Phone Number with Country Code
          PhoneInputField(
            phoneController: _phoneController,
            labelText: 'Phone Number *',
            hintText: 'Enter your phone number',
            onCountryCodeChanged: (countryCode) {
              setState(() {
                _selectedCountryCode = countryCode;
              });
            },
          ),
          const SizedBox(height: 20),

          // Gender
          const Text(
            'Gender *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Male'),
                  value: 'Male',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: const Text('Female'),
                  value: 'Female',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: const Text('Other'),
                  value: 'Other',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Date of Birth
          const Text(
            'Date of Birth *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDateOfBirth,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Image.asset(
                      'assets/images/calendar_icon_new.png',
                      width: 20,
                      height: 20,
                      color: const Color(0xFF2F51A7),
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Color(0xFF2F51A7),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDateOfBirth != null
                        ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                        : 'Select your date of birth',
                    style: TextStyle(
                      color:
                          _selectedDateOfBirth != null
                              ? AppColors.black
                              : AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Age (Auto-calculated)
          const Text(
            'Age *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            readOnly: true,
            decoration: const InputDecoration(
              hintText: 'Age will be calculated from date of birth',
              prefixIcon: Icon(Icons.cake, color: Color(0xFF2F51A7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Address Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Street Address
          const Text(
            'Street Address *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              hintText: 'Enter your street address',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              prefixIcon: Icon(Icons.home, color: Color(0xFF2F51A7)),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Country Dropdown
          const Text(
            'Country *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          CustomDropdownField(
            labelText: '',
            hintText: 'Select your country',
            value: _selectedCountry,
            items: _countries,
            onChanged: (value) {
              print('🔍 DEBUG: Country changed to: $value');
              setState(() {
                _selectedCountry = value;
                // Clear city and state when country changes
                _selectedCity = null;
                _selectedState = null;
              });
              print('🔍 DEBUG: After setState, _selectedCountry = $_selectedCountry');
            },
            enableSearch: true,
            prefixIcon: Icons.public_rounded,
            modalTitle: 'Select Country',
          ),
          const SizedBox(height: 20),

          // City Dropdown
          const Text(
            'City *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          CustomDropdownField(
            labelText: '',
            hintText: 'Select your city',
            value: _availableCities.any((city) => city.value == _selectedCity) ? _selectedCity : null,
            items: _availableCities,
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
              });
            },
            enableSearch: true,
            prefixIcon: Icons.location_city_rounded,
            modalTitle: 'Select City',
          ),
          const SizedBox(height: 20),

          // State and ZIP in a row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedCountry == 'CA' ? 'Province' : _selectedCountry == 'GB' ? 'Region' : _selectedCountry == 'AU' ? 'State/Territory' : 'State'} *',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomDropdownField(
                      labelText: '',
                      hintText: _selectedCountry == 'CA' ? 'Select province' : _selectedCountry == 'GB' ? 'Select region' : _selectedCountry == 'AU' ? 'Select state/territory' : 'Select state',
                      value: _availableStates.any((state) => state.value == _selectedState) ? _selectedState : null,
                      items: _availableStates,
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                        });
                      },
                      enableSearch: true,
                      prefixIcon: Icons.map_rounded,
                      modalTitle: _selectedCountry == 'CA' ? 'Select Province' : _selectedCountry == 'GB' ? 'Select Region' : _selectedCountry == 'AU' ? 'Select State/Territory' : 'Select State',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedCountry == 'US' ? 'ZIP Code' : _selectedCountry == 'CA' ? 'Postal Code' : _selectedCountry == 'GB' ? 'Postcode' : _selectedCountry == 'AU' ? 'Postcode' : _selectedCountry == 'IN' ? 'PIN Code' : 'Postal Code'} *',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _zipController,
                      keyboardType: _selectedCountry == 'CA' || _selectedCountry == 'GB' ? TextInputType.text : TextInputType.number,
                      decoration: InputDecoration(
                        hintText: _selectedCountry == 'US' ? 'ZIP' : _selectedCountry == 'CA' ? 'K1A 0A6' : _selectedCountry == 'GB' ? 'SW1A 1AA' : _selectedCountry == 'AU' ? '2000' : _selectedCountry == 'IN' ? '110001' : 'Postal Code',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.local_post_office,
                          color: Color(0xFF2F51A7),
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEducationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Education & Background',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Education Level
          const Text(
            'Education Level *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          CustomDropdownField(
            labelText: '',
            hintText: 'Select your education level',
            value: _selectedEducationLevel.isEmpty ? null : _selectedEducationLevel,
            items: _educationLevels,
            onChanged: (value) {
              setState(() {
                _selectedEducationLevel = value ?? '';
              });
            },
            enableSearch: true,
            prefixIcon: Icons.school,
            modalTitle: 'Select Education Level',
          ),

          // Custom education field for "Other"
          if (_selectedEducationLevel == 'Other') ...[
            const SizedBox(height: 16),
            const Text(
              'Please specify your education level *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customEducationController,
              decoration: const InputDecoration(
                hintText: 'Enter your education level',
                prefixIcon: Icon(Icons.edit, color: Color(0xFF2F51A7)),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ],

          const SizedBox(height: 20),

          // College/Institution
          const Text(
            'College/Institution *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _collegeController,
            decoration: const InputDecoration(
              hintText: 'Enter your college or institution name',
              prefixIcon: Icon(Icons.business, color: Color(0xFF2F51A7)),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Bio
          const Text(
            'Bio (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Tell us about yourself, your interests, and what you\'re looking for...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsAndAvailabilityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skills & Availability',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Skills Section
          const Text(
            'Skills *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search and select skills that match your expertise',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 12),

          // Skills search field
          TextFormField(
            controller: _skillsSearchController,
            decoration: InputDecoration(
              hintText: 'Search skills...',
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF2F51A7),
              ),
              suffixIcon:
                  _skillsSearchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _skillsSearchController.clear();
                          _filterSkills('');
                        },
                      )
                      : null,
            ),
            onChanged: _filterSkills,
          ),

          // Selected skills chips
          if (_selectedSkills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _selectedSkills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedSkills.remove(skill);
                        });
                      },
                      backgroundColor: AppColors.gigAppPurple.withOpacity(0.1),
                      deleteIconColor: AppColors.gigAppPurple,
                    );
                  }).toList(),
            ),
          ],

          // Search results
          if (_skillsSearchController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  _filteredSkills.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'No matching skills found',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _addCustomSkill(_skillsSearchController.text),
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(
                                'Add "${_skillsSearchController.text.trim()}" as custom skill',
                                style: const TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gigAppPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredSkills.length,
                        itemBuilder: (context, index) {
                          final skill = _filteredSkills[index];
                          return ListTile(
                            title: Text(skill),
                            onTap: () {
                              setState(() {
                                if (!_selectedSkills.contains(skill)) {
                                  _selectedSkills.add(skill);
                                }
                                _skillsSearchController.clear();
                                _filterSkills('');
                              });
                            },
                          );
                        },
                      ),
            ),
          ],
          const SizedBox(height: 24),
          // Weekly Hours
          const Text(
            'Weekly Availability',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'How many hours per week are you available to work?',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _weeklyHours.toDouble(),
                  min: 5,
                  max: 40,
                  divisions: 7,
                  label: '$_weeklyHours hours',
                  onChanged: (value) {
                    setState(() {
                      _weeklyHours = value.round();
                    });
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gigAppPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_weeklyHours hrs/week',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.gigAppPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Time Slots
          const Text(
            'Preferred Time Slots *',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your preferred working hours',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 12),

          Column(
            children:
                _availableTimeSlots.map((timeSlot) {
                  final isSelected = _selectedTimeSlots.contains(timeSlot);
                  return CheckboxListTile(
                    title: Text(timeSlot),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedTimeSlots.add(timeSlot);
                        } else {
                          _selectedTimeSlots.remove(timeSlot);
                        }
                      });
                    },
                    activeColor: AppColors.gigAppPurple,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAndResumeUploadPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile & Documents',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a profile photo and upload your resume to stand out',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 24),

          // Profile Image Section
          Row(
            children: [
              const Text(
                'Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Text(' *', style: TextStyle(color: Colors.red, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),

          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.grey.withOpacity(0.2),
                    border: Border.all(
                      color: AppColors.grey.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child:
                      _profileImage != null
                          ? ClipOval(
                            child: Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            ),
                          )
                          : const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.grey,
                          ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isUploadingImage ? null : _pickProfileImage,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gigAppPurple,
                      ),
                      child:
                          _isUploadingImage
                              ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Resume Section
          _buildResumeSection(),

          // Tips section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gigAppPurple.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gigAppPurple.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.gigAppPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tips for Success',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.gigAppPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• A professional profile photo increases your chances of getting hired by 40%\n'
                  '• Upload a well-formatted PDF resume to showcase your experience\n'
                  '• Both are required to complete your profile and apply for jobs',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Resume',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Text(' *', style: TextStyle(color: Colors.red, fontSize: 18)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload your resume in PDF format',
          style: TextStyle(fontSize: 14, color: AppColors.grey),
        ),
        const SizedBox(height: 12),
        if (_resumeFile != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gigAppLightPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gigAppPurple.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: AppColors.gigAppPurple,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _resumeFileName ?? 'Resume uploaded',
                    style: const TextStyle(
                      color: AppColors.gigAppPurple,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUploadingResume ? null : _pickResume,
            icon:
                _isUploadingResume
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gigAppPurple,
                      ),
                    )
                    : const Icon(Icons.upload_file),
            label: Text(
              _resumeFile == null ? 'Upload Resume' : 'Change Resume',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gigAppPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.gigAppPurple.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }
}
