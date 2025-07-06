import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

class SleepButton extends StatelessWidget {
  final bool isTracking;
  final bool isLoading;
  final VoidCallback onPressed;

  const SleepButton({
    Key? key,
    required this.isTracking,
    required this.isLoading,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isTracking
                  ? [
                      const Color(0xFFFF6B6B),
                      const Color(0xFFFF8787),
                    ]
                  : [
                      AppTheme.primaryColor,
                      AppTheme.secondaryColor,
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: (isTracking
                        ? const Color(0xFFFF6B6B)
                        : AppTheme.primaryColor)
                    .withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isTracking ? Icons.stop : Icons.bedtime,
                        size: 60,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isTracking ? '起床する' : '睡眠開始',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}