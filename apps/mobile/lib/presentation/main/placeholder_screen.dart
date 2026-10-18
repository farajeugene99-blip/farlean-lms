import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String targetPhase;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetPhase,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.primaryColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: context.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  targetPhase,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warning,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
