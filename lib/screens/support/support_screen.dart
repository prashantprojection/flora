import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/utils/network_utils.dart';

import 'package:flora/screens/support/components/support_donation_card.dart';
import 'package:flora/screens/support/components/support_backup_card.dart';
import 'package:flora/screens/support/components/support_upi_card.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  Future<void> _launchURL(String urlString) async {
    // 1. GATEKEEPER: Check Internet
    final hasInternet = await NetworkUtils.hasInternetConnection();
    if (!hasInternet) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No internet connection available."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final Uri uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.heartHandshake,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Support Us',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('assets/logo.png', height: 120),
            const SizedBox(height: 16),
            Text(
              'Support the Developer',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Flora is a labor of love, dedicated to providing you the best plant care experience. Your support helps me keep improving the app and adding new features for free.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            SupportDonationCard(
              onDonate: () => _launchURL('https://www.buymeacoffee.com/nemi_nemesis'),
            ),
            const SizedBox(height: 16),

            SupportUpiCard(
              onDonate: (amount, remark) {
                _launchURL(
                  'upi://pay?pa=py2738-1@oksbi&pn=Flora&am=$amount&cu=INR&tn=$remark',
                );
              },
            ),
            const SizedBox(height: 16),

            const SupportBackupCard(),

            const SizedBox(height: 24),
            Text(
              'Thank you for your contribution!',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(60),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 80), // Bottom padding for nav bar
          ],
        ),
      ),
    );
  }
}
