import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String assetPath;

  const LegalScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  static Route<void> route({required String title, required String assetPath}) {
    return MaterialPageRoute(
      builder: (_) => LegalScreen(title: title, assetPath: assetPath),
    );
  }

  Future<String> _loadLegalDocument() async {
    return await rootBundle.loadString(assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: _loadLegalDocument(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'ドキュメントの読み込みに失敗しました',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Markdown(
            data: snapshot.data ?? '',
            styleSheet: MarkdownStyleSheet(
              h1: Theme.of(context).textTheme.headlineMedium,
              h2: Theme.of(context).textTheme.headlineSmall,
              h3: Theme.of(context).textTheme.titleLarge,
              p: Theme.of(context).textTheme.bodyMedium,
              listBullet: Theme.of(context).textTheme.bodyMedium,
            ),
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrl(Uri.parse(href));
              }
            },
          );
        },
      ),
    );
  }
}

// プライバシーポリシー画面
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static Route<void> route() {
    return LegalScreen.route(
      title: 'プライバシーポリシー',
      assetPath: 'assets/legal/privacy_policy_ja.md',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'プライバシーポリシー',
      assetPath: 'assets/legal/privacy_policy_ja.md',
    );
  }
}

// 利用規約画面
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static Route<void> route() {
    return LegalScreen.route(
      title: '利用規約',
      assetPath: 'assets/legal/terms_of_service_ja.md',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: '利用規約',
      assetPath: 'assets/legal/terms_of_service_ja.md',
    );
  }
}