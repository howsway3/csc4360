import 'package:flutter/material.dart';

class AchievementBadge extends StatelessWidget {
  final String title;
  final String emoji;
  final bool earned;
  
  const AchievementBadge({
    super.key,
    required this.title,
    required this.emoji,
    this.earned = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: earned
            ? const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              )
            : LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[400]!],
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: earned ? [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ] : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: earned ? 1.0 : 0.3,
            child: Text(
              emoji,
              style: const TextStyle(
                fontSize: 32,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: earned ? Colors.white : Colors.grey[600],
            ),
          ),
          if (earned) ...[
            const SizedBox(height: 4),
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }
}

class BadgeDisplay extends StatelessWidget {
  final List<String> badges;
  
  const BadgeDisplay({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        AchievementBadge(
          title: 'Strong Password\nMaster',
          emoji: '🔐',
          earned: badges.contains('Strong Password Master'),
        ),
        AchievementBadge(
          title: 'The Early Bird\nSpecial',
          emoji: '🌅',
          earned: badges.contains('The Early Bird Special'),
        ),
        AchievementBadge(
          title: 'Profile\nCompleter',
          emoji: '✨',
          earned: badges.contains('Profile Completer'),
        ),
      ],
    );
  }
}