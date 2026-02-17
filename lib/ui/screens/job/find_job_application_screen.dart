import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class FindJobApplicationScreen extends StatefulWidget {
  const FindJobApplicationScreen({super.key});

  @override
  State<FindJobApplicationScreen> createState() =>
      _FindJobApplicationScreenState();
}

class _FindJobApplicationScreenState extends State<FindJobApplicationScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _visaStatusController = TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _subCategoryController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();

  String _jobStatus = 'fresher'; // 'fresher' or 'experienced'

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _visaStatusController.dispose();
    _qualificationController.dispose();
    _jobTitleController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  void _clearAll() {
    _fullNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _locationController.clear();
    _visaStatusController.clear();
    _qualificationController.clear();
    _jobTitleController.clear();
    _categoryController.clear();
    _subCategoryController.clear();
    _industryController.clear();
    setState(() {
      _jobStatus = 'fresher';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.secondaryColor,
      appBar: UiUtils.buildAppBar(
        context,
        title: "Jobs",
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Full Name"),
                  _buildTextField(_fullNameController, "Cliff Clavin"),
                  const SizedBox(height: 16),
                  _buildLabel("Email Id"),
                  _buildTextField(_emailController, "Cliff Clavin12@gmail.com"),
                  _buildHelperText(
                      "This wont affect your login credentials for ebozor"),
                  const SizedBox(height: 16),
                  _buildLabel("Phone No"),
                  _buildTextField(_phoneController, "+91 9876543219"),
                  _buildHelperText(
                      "This wont affect your login credentials for ebozor"),
                  const SizedBox(height: 16),
                  _buildLabel("Located In"),
                  _buildTextField(_locationController, "Search"),
                  const SizedBox(height: 16),
                  _buildLabel("Visa Status"),
                  _buildTextField(_visaStatusController, "Visa status"),
                  const SizedBox(height: 16),
                  _buildLabel("Qualification degree"),
                  _buildTextField(_qualificationController, "Visa status"),
                  const SizedBox(height: 16),
                  _buildLabel("Job Status"),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectableBox("fresher", "fresher"),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child:
                            _buildSelectableBox("Experienced", "Experienced"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLabel("Job Title"),
                  _buildTextField(_jobTitleController, "Visa status"),
                  const SizedBox(height: 16),
                  _buildLabel("Category"),
                  _buildTextField(_categoryController, "Visa status"),
                  const SizedBox(height: 16),
                  _buildLabel(
                      "Category"), // Duplicate in screenshot/request, assuming Sub-Category or keeping as is
                  _buildTextField(_subCategoryController, "Visa status"),
                  const SizedBox(height: 16),
                  _buildTextField(_industryController, "Industry"),
                  const SizedBox(height: 80), // Space for bottom buttons
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: context.color.textDefaultColor.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildHelperText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.withOpacity(0.5),
          fontSize: 14,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.color.territoryColor),
        ),
        filled: true,
        fillColor: Colors.white, // As per screenshot, fields look white
      ),
    );
  }

  Widget _buildSelectableBox(String title, String value) {
    bool isSelected = _jobStatus.toLowerCase() == value.toLowerCase();
    return GestureDetector(
      onTap: () {
        setState(() {
          _jobStatus = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.withOpacity(0.3),
          ),
          color: isSelected ? Colors.grey.withOpacity(0.1) : Colors.white,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.withOpacity(
                0.7), // Screenshot shows grey text even for what might be selected? Or maybe simple toggle.
            // Let's stick to screenshot look, text looks grey.
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearAll,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.color.textDefaultColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                "Clear All",
                style: TextStyle(
                  color: context.color.textDefaultColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2, // Save & Apply is wider
            child: ElevatedButton(
              onPressed: () {
                // Apply logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: const Text(
                "Save & Apply",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
