import 'package:flora/utils/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flora/utils/app_theme.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  void _launchUpiUrl(String amount) {
    _launchURL(
      'upi://pay?pa=py2738-1@oksbi&pn=Flora+Dev&am=$amount&cu=INR&tn=Supporting+Flora+App',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero Section ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroSection(),
          ),

          // ── Content ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Section label
                const _SectionLabel(
                  icon: LucideIcons.heart,
                  label: 'Make a Contribution',
                  color: Color(0xFFE87070),
                ),
                const SizedBox(height: 12),

                // Buy Me a Coffee
                SupportDonationCard(
                  onDonate: () =>
                      _launchURL('https://www.buymeacoffee.com/nemi_nemesis'),
                ),
                const SizedBox(height: 16),

                // UPI Section
                const _SectionLabel(
                  icon: LucideIcons.smartphoneNfc,
                  label: 'Quick Pay (India)',
                  color: Color(0xFF5B67CA),
                ),
                const SizedBox(height: 12),
                SupportUpiCard(onPay: _launchUpiUrl),

                const SizedBox(height: 24),

                // Section label
                const _SectionLabel(
                  icon: LucideIcons.databaseBackup,
                  label: 'Garden Backup',
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 12),

                const SupportBackupCard(),

                const SizedBox(height: 32),

                // Footer
                Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.sprout,
                        size: 20,
                        color: AppTheme.primary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Built with love for plant lovers 🌿',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Section Widget ───────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF2A3320),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              // Top bar label
              Row(
                children: [
                  Icon(
                    LucideIcons.heartHandshake,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Support Us',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mascot
              Image.asset(
                AppAssets.supportFlo,
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  LucideIcons.sprout,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 20),

              // Headline
              Text(
                'Keep Flora Growing 🌱',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Flora is a free labor of love. Your support directly funds new features, AI improvements, and keeps the app alive.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),

              // Feature pills row
              const Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FeaturePill(icon: LucideIcons.zap, label: 'AI-Powered'),
                  _FeaturePill(icon: LucideIcons.leaf, label: 'Open & Honest'),
                  _FeaturePill(icon: LucideIcons.gift, label: 'Free Forever'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature Pill ─────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}


