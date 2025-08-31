import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/theme_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _heightController = TextEditingController();
  
  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _profileImageUrl;
  XFile? _pickedImage;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user != null) {
      _displayNameController.text = user.displayName;
      _selectedGender = user.gender;
      _selectedDate = user.dateOfBirth;
      _heightController.text = user.height?.toString() ?? '';
      _profileImageUrl = user.profilePictureUrl;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
      });
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_pickedImage == null) return _profileImageUrl;
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_pictures').child('$uid.jpg');
      await ref.putData(await _pickedImage!.readAsBytes());
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        String? imageUrl = _profileImageUrl;
        if (_pickedImage != null && authProvider.user != null) {
          imageUrl = await _uploadProfileImage(authProvider.user!.uid);
        }
        final success = await authProvider.updateUserProfile(
          displayName: _displayNameController.text.trim(),
          gender: _selectedGender,
          dateOfBirth: _selectedDate,
          height: _heightController.text.isNotEmpty 
              ? double.tryParse(_heightController.text) 
              : null,
          profilePictureUrl: imageUrl,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isEditing = false;
            _pickedImage = null;
            _profileImageUrl = imageUrl;
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Failed to update profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logoutUser();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header
                  _buildProfileHeader(user),
                  const SizedBox(height: 32),

                  // Profile Form
                  _buildProfileForm(),
                  const SizedBox(height: 32),

                  // Theme Toggle
                  _buildThemeToggle(),
                  const SizedBox(height: 32),

                  // Actions
                  if (_isEditing) _buildEditActions(),
                  
                  // Logout Button
                  _buildLogoutButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    if (_pickedImage != null) {
      return FutureBuilder<Uint8List>(
        future: _pickedImage!.readAsBytes(),
        builder: (context, snapshot) {
          Widget avatar;
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            avatar = CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF6750A4).withOpacity(0.1),
              backgroundImage: MemoryImage(snapshot.data!),
              child: null,
            );
          } else {
            avatar = const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF6750A4),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            );
          }
          return Column(
            children: [
              Stack(
                children: [
                  avatar,
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.camera_alt, color: const Color(0xFF6750A4)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          );
        },
      );
    }
    final imageProvider = (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
        ? NetworkImage(user.profilePictureUrl!)
        : null;
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF6750A4).withOpacity(0.1),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(
                      Icons.person,
                      size: 50,
                      color: const Color(0xFF6750A4),
                    )
                  : null,
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 4,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.camera_alt, color: const Color(0xFF6750A4)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.displayName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Display Name
        CustomTextField(
          controller: _displayNameController,
          labelText: 'Display Name',
          hintText: 'Enter your display name',
          prefixIcon: Icons.person_outlined,
          enabled: _isEditing,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your display name';
            }
            if (value.length < 2) {
              return 'Display name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Gender
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            labelText: 'Gender',
            hintText: 'Select your gender',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.light
                ? Colors.grey[50]
                : Colors.grey[900],
          ),
          items: _genderOptions.map((String gender) {
            return DropdownMenuItem<String>(
              value: gender,
              child: Text(gender),
            );
          }).toList(),
          onChanged: _isEditing ? (String? newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          } : null,
          validator: (value) => null, // Optional field
        ),
        const SizedBox(height: 20),

        // Date of Birth
        InkWell(
          onTap: _isEditing ? _selectDate : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date of Birth',
              hintText: _selectedDate != null
                  ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                  : 'Select your date of birth',
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[50]
                  : Colors.grey[900],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _selectedDate != null
                    ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                    : 'Select your date of birth',
                style: TextStyle(
                  color: _selectedDate != null 
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Height
        CustomTextField(
          controller: _heightController,
          labelText: 'Height (cm)',
          hintText: 'Enter your height in cm',
          prefixIcon: Icons.height_outlined,
          keyboardType: TextInputType.number,
          enabled: _isEditing,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final height = double.tryParse(value);
              if (height == null || height < 50 || height > 300) {
                return 'Please enter a valid height (50-300 cm)';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildThemeToggle() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {

        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(
                  themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: const Color(0xFF6750A4),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        themeService.isDarkMode ? 'Dark Mode' : 'Light Mode',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: themeService.isDarkMode,
                  onChanged: (value) {
                    themeService.toggleTheme();
                  },
                  activeColor: const Color(0xFF6750A4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
                _loadUserData(); // Reset to original values
              });
            },
            child: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6750A4)),
              foregroundColor: const Color(0xFF6750A4),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            onPressed: _isLoading ? null : _saveProfile,
            text: _isLoading ? 'Saving...' : 'Save Changes',
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return CustomButton(
      onPressed: _logout,
      text: 'Logout',
      backgroundColor: Colors.red,
      icon: Icons.logout,
    );
  }
}
