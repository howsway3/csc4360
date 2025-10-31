import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/avatar_selector.dart';
import '../widgets/password_strength_meter.dart';
import '../widgets/progress_tracker.dart';
import '../models/user_data.dart';
import 'success_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _selectedAvatar;
  
  final Map<String, bool> _fieldValidation = {
    'name': false,
    'email': false,
    'password': false,
    'dob': false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
        _fieldValidation['dob'] = true;
      });
      _triggerHapticFeedback();
    }
  }

  void _triggerHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedAvatar != null) {
      setState(() {
        _isLoading = true;
      });
      
      final userData = UserData(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        dob: _dobController.text,
        selectedAvatar: _selectedAvatar,
      );
      
      userData.badges = userData.calculateBadges();
      
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessScreen(userData: userData),
          ),
        );
      });
    } else if (_selectedAvatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose an avatar! '),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Account '),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                ProgressTracker(
                  name: _nameController.text,
                  email: _emailController.text,
                  password: _passwordController.text,
                  dob: _dobController.text,
                  avatar: _selectedAvatar,
                ),
                const SizedBox(height: 24),
                
                AvatarSelector(
                  selectedAvatar: _selectedAvatar,
                  onAvatarSelected: (avatar) {
                    setState(() {
                      _selectedAvatar = avatar;
                    });
                    _triggerHapticFeedback();
                  },
                ),
                const SizedBox(height: 24),
                
                _buildAnimatedTextField(
                  controller: _nameController,
                  label: 'Adventure Name',
                  icon: Icons.person,
                  fieldKey: 'name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'What should we call you on this adventure?';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                _buildAnimatedTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email,
                  fieldKey: 'email',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'We need your email for adventure updates!';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Oops! That doesn\'t look like a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: const Icon(Icons.calendar_today, 
                        color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: _fieldValidation['dob'] == true 
                        ? Colors.green[50] 
                        : Colors.grey[50],
                    suffixIcon: _fieldValidation['dob'] == true
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.date_range),
                            onPressed: _selectDate,
                          ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'When did your adventure begin?';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                _buildAnimatedTextField(
                  controller: _passwordController,
                  label: 'Secret Password',
                  icon: Icons.lock,
                  fieldKey: 'password',
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible 
                          ? Icons.visibility 
                          : Icons.visibility_off,
                      color: Colors.deepPurple,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Every adventurer needs a secret password!';
                    }
                    if (value.length < 6) {
                      return 'Make it stronger! At least 6 characters';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                
                PasswordStrengthMeter(password: _passwordController.text),
                const SizedBox(height: 30),
                
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isLoading ? 60 : double.infinity,
                  height: 60,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.deepPurple),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 5,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Start My Adventure',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.rocket_launch, color: Colors.white),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String fieldKey,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onChanged,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(
        begin: 1.0,
        end: _fieldValidation[fieldKey] == true ? 1.02 : 1.0,
      ),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: Colors.deepPurple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: _fieldValidation[fieldKey] == true
                  ? Colors.green[50]
                  : Colors.grey[50],
              suffixIcon: _fieldValidation[fieldKey] == true && suffixIcon == null
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : suffixIcon,
            ),
            validator: (value) {
              final result = validator(value);
              if (mounted) {
                Future.microtask(() {
                  if (mounted) {
                    setState(() {
                      _fieldValidation[fieldKey] = result == null;
                    });
                  }
                });
              }
              return result;
            },
            onChanged: (value) {
              if (onChanged != null) onChanged(value);
              if (value.isNotEmpty) {
                final result = validator(value);
                setState(() {
                  _fieldValidation[fieldKey] = result == null;
                  if (result == null) _triggerHapticFeedback();
                });
              }
            },
          ),
        );
      },
    );
  }
}