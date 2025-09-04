import 'package:flutter/material.dart';

class AppErrorWidget extends StatelessWidget {
  final String? title;
  final String message;
  final String? assetPath;
  final VoidCallback? onRetry;
  final bool showRetry;

  const AppErrorWidget({
    super.key,
    this.title,
    required this.message,
    this.assetPath, // If not provided, fallback to icon
    this.onRetry,
    this.showRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (assetPath != null)
              Image.asset(
                assetPath!,
                width: 120,
                height: 120,
              )
            else
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
            const SizedBox(height: 24),
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (showRetry && onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Specific variations
class NoInternetWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      assetPath: 'assets/images/no_internet.png',
      onRetry: onRetry,
    );
  }
}

class ServerErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const ServerErrorWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      title: 'Server Error',
      message: 'Something went wrong with our servers. Please try again later.',
      assetPath: 'assets/images/server_error.png',
      onRetry: onRetry,
    );
  }
}
