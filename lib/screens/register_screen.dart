import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  bool _isLoading = false;
  String _selectedUserType = 'Women';
  bool _obscurePassword = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _badgeController = TextEditingController();
  final _stationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _badgeController.dispose();
    _stationController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    print('=================== Starting Registration Process ===================');
    print('Form validation completed. Proceeding to save data...');

    String? userId;
    bool isSuccess = false;

    try {
      // Generate unique ID based on user type
      String generatedId;
      switch (_selectedUserType) {
        case 'Women':
          generatedId = 'W${DateTime.now().millisecondsSinceEpoch}${_emailController.text.hashCode.abs()}';
          break;
        case 'Police':
          generatedId = 'P${DateTime.now().millisecondsSinceEpoch}${_badgeController.text.hashCode.abs()}';
          break;
        case 'Guardian':
          generatedId = 'G${DateTime.now().millisecondsSinceEpoch}${_emailController.text.hashCode.abs()}';
          break;
        default:
          generatedId = 'U${DateTime.now().millisecondsSinceEpoch}${_emailController.text.hashCode.abs()}';
      }

      print('Generated ID for ${_selectedUserType}: $generatedId');
      
      print('Preparing data for Firestore:');
      print('- ID: $generatedId');
      print('- Name: ${_nameController.text.trim()}');
      print('- Email: ${_emailController.text.trim()}');
      print('- Phone: ${_phoneController.text.trim()}');
      print('- User Type: $_selectedUserType');
      
      // Create user data with generated ID
      final userData = {
        'id': generatedId,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'userType': _selectedUserType,
        'password': _passwordController.text,
        'address': _selectedUserType == 'Women' ? _addressController.text.trim() : null,
        'badgeNumber': _selectedUserType == 'Police' ? _badgeController.text.trim() : null,
        'stationAddress': _selectedUserType == 'Police' ? _stationController.text.trim() : null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      final userRef = await _userService.createUserWithData(userData);
      userId = userRef.id;
      
      print('User data saved successfully! User ID: $userId');
      print('Registration complete. Returning to previous screen...');
      isSuccess = true;
    } catch (error) {
      print('ERROR during registration: $error');
      print('Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $error')),
        );
      }
    } finally {
      // Ensure we reset the loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      print('User ID created: ${userId ?? 'null'}');
      print('=================== End Registration Process ===================');
    }

    // Handle successful registration outside of try-catch-finally
    if (isSuccess && mounted) {
      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );
      
      // Navigate back to previous screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[600]!,
              Colors.blue[800]!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          value: _selectedUserType,
                          decoration: InputDecoration(
                            labelText: 'User Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.blue[50],
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Women', child: Text('Women')),
                            DropdownMenuItem(value: 'Police', child: Text('Police')),
                            DropdownMenuItem(value: 'Guardian', child: Text('Guardian')),
                          ],
                          onChanged: _isLoading ? null : (value) {
                            setState(() {
                              _selectedUserType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.blue[50],
                            prefixIcon: const Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.blue[50],
                            prefixIcon: const Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.blue[50],
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            filled: true,
                            fillColor: Colors.blue[50],
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        if (_selectedUserType == 'Women') ...[
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'Address',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              filled: true,
                              fillColor: Colors.blue[50],
                              prefixIcon: const Icon(Icons.location_on),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your address';
                              }
                              return null;
                            },
                          ),
                        ],
                        if (_selectedUserType == 'Police') ...[
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _badgeController,
                            decoration: InputDecoration(
                              labelText: 'Badge Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              filled: true,
                              fillColor: Colors.blue[50],
                              prefixIcon: const Icon(Icons.badge),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your badge number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _stationController,
                            decoration: InputDecoration(
                              labelText: 'Station Address',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              filled: true,
                              fillColor: Colors.blue[50],
                              prefixIcon: const Icon(Icons.location_city),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your station address';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Register',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 