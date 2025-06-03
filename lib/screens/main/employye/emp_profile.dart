import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_work_app/screens/main/employye/emp_ob/cd_servi.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:get_work_app/services/auth_services.dart';

class EmpProfile extends StatefulWidget {
  const EmpProfile({super.key});

  @override
  State<EmpProfile> createState() => _EmpProfileState();
}

class _EmpProfileState extends State<EmpProfile> {
  Map<String, dynamic>? employerData;
  Map<String, dynamic>? companyInfo;
  bool isEditing = false;
  bool isUploadingLogo = false;
  bool isLoading = true;

  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _companyAddressController =
      TextEditingController();
  final TextEditingController _companyDescriptionController =
      TextEditingController();
  final TextEditingController _companyWebsiteController =
      TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _employeeCountController =
      TextEditingController();
  final TextEditingController _establishedYearController =
      TextEditingController();

  String? logoUrl;
  final ImagePicker _picker = ImagePicker();

  // Add company size options
  final List<String> _companySizes = [
    '1-10 employees',
    '11-50 employees',
    '51-200 employees',
    '201-500 employees',
    '500+ employees',
  ];
  String? _selectedCompanySize;

  @override
  void initState() {
    super.initState();
    _fetchEmployerData();
  }

  Future<void> _fetchEmployerData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final userData = await AuthService.getUserData();
      final companyData = await AuthService.getEmployeeCompanyInfo();

      if (mounted) {
        setState(() {
          employerData = userData;
          companyInfo = companyData;
          logoUrl = companyData?['companyLogo'] ?? '';
          _selectedCompanySize = companyData?['companySize'];
          _populateControllers();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching employer data: $e');
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error loading profile data: $e', isError: true);
    }
  }

  void _populateControllers() {
    if (companyInfo != null) {
      _industryController.text = companyInfo?['industry'] ?? '';
      _companyAddressController.text = companyInfo?['companyAddress'] ?? '';
      _companyDescriptionController.text =
          companyInfo?['companyDescription'] ?? '';
      _companyWebsiteController.text = companyInfo?['companyWebsite'] ?? '';
      _companyEmailController.text = companyInfo?['companyEmail'] ?? '';
      _companyPhoneController.text = companyInfo?['companyPhone'] ?? '';
      _employeeCountController.text = companyInfo?['employeeCount'] ?? '';
      _establishedYearController.text = companyInfo?['establishedYear'] ?? '';
      logoUrl = companyInfo?['companyLogo'];
    }
  }

  Future<void> _uploadLogo() async {
    try {
      setState(() {
        isUploadingLogo = true;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final String? uploadedUrl = await CloudinaryService.uploadImage(
          imageFile,
        );

        if (uploadedUrl != null) {
          setState(() {
            logoUrl = uploadedUrl;
          });

          // Update in Firestore
          await _updateProfileField('companyLogo', logoUrl!);

          _showSnackBar('Logo updated successfully!');
        } else {
          _showSnackBar('Failed to upload logo', isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Error uploading logo: $e', isError: true);
      print('Logo upload error: $e');
    } finally {
      setState(() {
        isUploadingLogo = false;
      });
    }
  }

  Future<void> _updateProfileField(String field, dynamic value) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({field: value});
      } catch (e) {
        print('Error updating field: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Map<String, dynamic> updatedData = {
          'industry': _industryController.text,
          'companyAddress': _companyAddressController.text,
          'companyDescription': _companyDescriptionController.text,
          'companyWebsite': _companyWebsiteController.text,
          'companyEmail': _companyEmailController.text,
          'companyPhone': _companyPhoneController.text,
          'companySize': _selectedCompanySize,
          'employeeCount': _employeeCountController.text,
          'establishedYear': _establishedYearController.text,
          'companyLogo': logoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update(updatedData);

        setState(() {
          companyInfo = {...companyInfo ?? {}, ...updatedData};
          isEditing = false;
        });

        _showSnackBar('Profile updated successfully!');
      }
    } catch (e) {
      _showSnackBar('Error updating profile: $e', isError: true);
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  _showSnackBar('Error logging out: $e', isError: true);
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            enabled: isEditing,
            decoration: InputDecoration(
              filled: true,
              fillColor: isEditing ? Colors.white : Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF4285F4),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonEditableField({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: TextStyle(
                fontSize: 16,
                color: value.isEmpty ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTile({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.only(bottom: 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.grey[700], size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        iconColor: Colors.grey[600],
        collapsedIconColor: Colors.grey[600],
        children: children,
      ),
    );
  }

    Widget _buildCompanySizeField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Company Size',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (isEditing)
            DropdownButtonFormField<String>(
              value: _selectedCompanySize,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4285F4),
                    width: 2,
                  ),
                ),
              ),
              items: _companySizes.map((size) {
                return DropdownMenuItem(
                  value: size,
                  child: Text(size),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCompanySize = value;
                });
              },
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _selectedCompanySize ?? 'Not provided',
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedCompanySize == null ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final fullName = employerData?['fullName'] ?? 'Full Name';
    final companyName = companyInfo?['companyName'] ?? 'Company Name';
    final industry = companyInfo?['industry'] ?? 'Industry';
    final employeeCount = companyInfo?['employeeCount'] ?? '0';
    final establishedYear = companyInfo?['establishedYear'] ?? 'N/A';
    final companySize = companyInfo?['companySize'] ?? 'N/A';

     return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF4285F4),
            elevation: 0,
            actions: [
              if (isEditing)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      isEditing = false;
                      _populateControllers();
                    });
                  },
                ),
              IconButton(
                icon: Icon(
                  isEditing ? Icons.check : Icons.edit,
                  color: Colors.white,
                ),
                onPressed:
                    isEditing
                        ? _saveProfile
                        : () => setState(() => isEditing = true),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4285F4), Color(0xFF1976D2)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Stack(
  alignment: Alignment.center,
  children: [
    Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(50),
      ),
    ),
    Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(45),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: logoUrl != null && logoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(45),
              child: Image.network(
                logoUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      companyName.isNotEmpty
                          ? companyName[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Color(0xFF4285F4),
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            )
          : Center(
              child: Text(
                companyName.isNotEmpty
                    ? companyName[0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    ),
    if (isEditing)
      Positioned(
        bottom: 0,
        right: 0,
        child: GestureDetector(
          onTap: _uploadLogo,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: isUploadingLogo
                ? const Padding(
                    padding: EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4285F4),
                    ),
                  )
                : const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Color(0xFF4285F4),
                  ),
          ),
        ),
      ),
  ],
),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              companyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (industry.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  industry,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildStatCard(
                        title: 'Employees',
                        value: employeeCount,
                        icon: Icons.people_outline,
                        color: const Color(0xFF4CAF50),
                      ),
                      _buildStatCard(
                        title: 'Since',
                        value: establishedYear,
                        icon: Icons.access_time,
                        color: const Color(0xFF2196F3),
                      ),
                      _buildStatCard(
                        title: 'Size',
                        value: companySize.split(' ')[0],
                        icon: Icons.business,
                        color: const Color(0xFFFF9800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTile(
                  title: 'Company Information',
                  icon: Icons.business,
                  children: [
                    _buildNonEditableField(
                      label: 'Company Name',
                      value: companyName,
                    ),
                    _buildEditableField(
                      label: 'Industry',
                      controller: _industryController,
                    ),
                    _buildEditableField(
                      label: 'Company Address',
                      controller: _companyAddressController,
                      maxLines: 2,
                    ),
                    _buildEditableField(
                      label: 'Company Description',
                      controller: _companyDescriptionController,
                      maxLines: 3,
                    ),
                                        _buildCompanySizeField(), // Use the new dropdown widget

                    _buildEditableField(
                      label: 'Employee Count',
                      controller: _employeeCountController,
                      keyboardType: TextInputType.number,
                    ),
                    _buildEditableField(
                      label: 'Established Year',
                      controller: _establishedYearController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),

                _buildSectionTile(
                  title: 'Contact Information',
                  icon: Icons.contact_phone,
                  children: [
                    _buildEditableField(
                      label: 'Company Website',
                      controller: _companyWebsiteController,
                      keyboardType: TextInputType.url,
                    ),
                    _buildEditableField(
                      label: 'Company Email',
                      controller: _companyEmailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildEditableField(
                      label: 'Company Phone',
                      controller: _companyPhoneController,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),

                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: const Text(
                      'Sign out of your account',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    onTap: _handleLogout,
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _industryController.dispose();
    _companyAddressController.dispose();
    _companyDescriptionController.dispose();
    _companyWebsiteController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _employeeCountController.dispose();
    _establishedYearController.dispose();
    super.dispose();
  }
}
