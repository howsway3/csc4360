class UserData {
  String name;
  String email;
  String password;
  String dob;
  String? selectedAvatar;
  List<String> badges;
  
  UserData({
    required this.name,
    required this.email,
    required this.password,
    required this.dob,
    this.selectedAvatar,
    this.badges = const [],
  });
  
  int getPasswordStrength() {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength;
  }
  
  bool isEarlyBird() {
    return DateTime.now().hour < 12;
  }
  
  List<String> calculateBadges() {
    List<String> earnedBadges = [];
    
    if (getPasswordStrength() >= 3) {
      earnedBadges.add('Strong Password Master');
    }
    
    if (isEarlyBird()) {
      earnedBadges.add('The Early Bird Special');
    }
    
    if (name.isNotEmpty && email.isNotEmpty && 
        password.isNotEmpty && dob.isNotEmpty && 
        selectedAvatar != null) {
      earnedBadges.add('Profile Completer');
    }
    
    return earnedBadges;
  }
}