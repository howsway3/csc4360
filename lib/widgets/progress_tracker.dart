import 'package:flutter/material.dart';

class ProgressTracker extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String dob;
  final String? avatar;
  
  const ProgressTracker({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.dob,
    this.avatar,
  });

  @override
  State<ProgressTracker> createState() => _ProgressTrackerState();
}

class _ProgressTrackerState extends State<ProgressTracker> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }
  
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
  
  int _calculateProgress() {
    int completed = 0;
    if (widget.name.isNotEmpty) completed++;
    if (widget.email.isNotEmpty) completed++;
    if (widget.password.isNotEmpty) completed++;
    if (widget.dob.isNotEmpty) completed++;
    if (widget.avatar != null) completed++;
    return completed;
  }
  
  double _getProgressPercentage() {
    return _calculateProgress() / 5.0;
  }
  
  String _getMilestoneMessage() {
    final progress = _getProgressPercentage() * 100;
    if (progress == 0) return 'Let\'s get started! ';
    if (progress >= 20 && progress < 40) return 'Great start! ';
    if (progress >= 40 && progress < 60) return 'Halfway there! ';
    if (progress >= 60 && progress < 100) return 'Almost done! ';
    if (progress == 100) return 'Ready for adventure! ';
    return '';
  }
  
  @override
  void didUpdateWidget(ProgressTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_calculateProgress() != _calculateProgressFromWidget(oldWidget)) {
      _animController.forward(from: 0);
    }
  }
  
  int _calculateProgressFromWidget(ProgressTracker widget) {
    int completed = 0;
    if (widget.name.isNotEmpty) completed++;
    if (widget.email.isNotEmpty) completed++;
    if (widget.password.isNotEmpty) completed++;
    if (widget.dob.isNotEmpty) completed++;
    if (widget.avatar != null) completed++;
    return completed;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = _getProgressPercentage();
    final message = _getMilestoneMessage();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Adventure Progress',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.deepPurple,
                ),
              ),
              ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                  CurvedAnimation(
                    parent: _animController,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: Text(
                  '${(percentage * 100).toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              tween: Tween<double>(begin: 0, end: percentage),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage < 0.5 ? Colors.orange : Colors.green,
                ),
                minHeight: 12,
              ),
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _animController,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}