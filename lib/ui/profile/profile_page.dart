import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/auth/data/auth_repository.dart';
import 'package:ai_teacher/core/locale/presentation/locale_controller.dart';
import 'package:ai_teacher/core/streak/presentation/streak_check_in_controller.dart';
import 'package:ai_teacher/core/user/data/user_repository.dart';
import 'package:ai_teacher/core/user/presentation/current_user_controller.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/profile/cards_sheet.dart';
import 'package:ai_teacher/ui/profile/edit_password_dialog.dart';
import 'package:ai_teacher/ui/profile/edit_profile_dialog.dart';
import 'package:ai_teacher/ui/profile/language_picker_sheet.dart';
import 'package:ai_teacher/ui/profile/subscription_details_sheet.dart';
import 'package:ai_teacher/ui/profile/widget/profile_group_card.dart';
import 'package:ai_teacher/ui/profile/widget/profile_leaderboard_card.dart';
import 'package:ai_teacher/ui/profile/widget/profile_pill_badge.dart';
import 'package:ai_teacher/ui/profile/widget/profile_row.dart';
import 'package:ai_teacher/ui/profile/widget/profile_section_label.dart';
import 'package:ai_teacher/ui/profile/widget/profile_toggle.dart';
import 'package:ai_teacher/ui/profile/widget/profile_trailing_value.dart';
import 'package:ai_teacher/ui/profile/widget/profile_user_card.dart';
import 'package:ai_teacher/utils/uz_phone_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _pushNotifications = true;
  bool _streakReminder = true;
  String? _appVersion;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = info.version);
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileLogout),
        content: Text(l10n.profileLogoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: Text(l10n.profileLogout),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    ref.invalidate(currentUserProvider);
    ref.invalidate(streakCheckInProvider);
    context.goNamed(AppRoute.onboarding.name);
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://www.myteacher.uz/docs/privacy_policy.html');
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  Future<void> _copyReferral(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).profileReferralCopied),
        ),
      );
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await image.readAsBytes();
      await ref.read(userRepositoryProvider).uploadAvatar(bytes, image.name);
      ref.invalidate(currentUserProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).profileAvatarUploadFailed,
              ),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _openEditProfile() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    await showDialog<bool>(
      context: context,
      builder: (_) => EditProfileDialog(initialFirstName: user.firstName),
    );
  }

  Future<void> _openEditPassword() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const EditPasswordDialog(),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).profilePasswordUpdated),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider) ?? const Locale('uz');
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isDemo = ref.watch(isDemoAccountProvider);
    final displayName = user?.fullName ?? '';
    final displayPhone = UzPhoneFormatter.formatInternational(
      user?.phoneNumber ?? '',
    );
    final displayInitial = user?.initial ?? '';
    final subscription = user?.activeSubscription;
    final hasActiveSubscription = subscription != null;
    final proPaketSubtitle = hasActiveSubscription
        ? _subscriptionSubtitle(l10n, locale, subscription.endDate)
        : l10n.profileNoActiveSubscription;
    final currentLanguageLabel = locale.languageCode == 'en'
        ? l10n.languageNameEnglish
        : l10n.languageNameUzbek;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileUserCard(
            name: displayName,
            subtitle: displayPhone,
            initial: displayInitial,
            avatarPath: user?.avatar,
            onTapAvatar: _pickAndUploadAvatar,
            uploadingAvatar: _uploadingAvatar,
          ),
          ProfileLeaderboardCard(
            onTap: () => context.pushNamed(AppRoute.leaderboard.name),
          ),
          ProfileSectionLabel(text: l10n.profileSectionAccount),
          ProfileGroupCard(
            children: [
              ProfileRow(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBackground: const Color(0xFFEFF6FF),
                title: l10n.profilePersonalInfo,
                subtitle: l10n.profileNameLabel,
                trailing: const ProfileTrailingValue(),
                onTap: _openEditProfile,
              ),
              ProfileRow(
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.primary,
                iconBackground: const Color(0xFFF0FDFA),
                title: l10n.profilePasswordLabel,
                subtitle: l10n.profileChangePassword,
                trailing: const ProfileTrailingValue(),
                onTap: _openEditPassword,
              ),
              ProfileRow(
                icon: Icons.phone_outlined,
                iconColor: const Color(0xFFFB923C),
                iconBackground: const Color(0xFFFFF7ED),
                title: l10n.profilePhoneLabel,
                subtitle: displayPhone,
                trailing: const ProfileTrailingValue(showChevron: false),
              ),
              ProfileRow(
                icon: Icons.mail_outline_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBackground: const Color(0xFFEFF6FF),
                title: l10n.profileEmailLabel,
                subtitle: (user?.email?.isNotEmpty ?? false)
                    ? user!.email!
                    : l10n.profileNotProvided,
                trailing: const ProfileTrailingValue(showChevron: false),
              ),
              if ((user?.referralCode ?? '').isNotEmpty)
                ProfileRow(
                  icon: Icons.qr_code_2_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  iconBackground: const Color(0xFFF5F3FF),
                  title: l10n.profileReferralCodeLabel,
                  subtitle: user!.referralCode!,
                  trailing: ProfileTrailingValue(
                    value: l10n.profileCopyLabel,
                    showChevron: false,
                  ),
                  onTap: () => _copyReferral(user.referralCode!),
                ),
            ],
          ),
          if (!isDemo) ...[
            ProfileSectionLabel(text: l10n.profileSectionSubscription),
            ProfileGroupCard(
              children: [
                ProfileRow(
                  icon: Icons.star_outline_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBackground: const Color(0xFFFEF9C3),
                  title: l10n.profileProPackage,
                  subtitle: proPaketSubtitle,
                  trailing: ProfileTrailingValue(
                    badge: hasActiveSubscription
                        ? ProfilePillBadge(
                            label: l10n.profileActiveBadge,
                            background: const Color(0xFFDCFCE7),
                            textColor: const Color(0xFF15803D),
                          )
                        : null,
                  ),
                  onTap: () => SubscriptionDetailsSheet.show(context),
                ),
                ProfileRow(
                  icon: Icons.credit_card_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBackground: const Color(0xFFEFF6FF),
                  title: l10n.profileCardsLabel,
                  subtitle: l10n.profilePaymentCards,
                  trailing: const ProfileTrailingValue(),
                  onTap: () => CardsSheet.show(context),
                ),
                ProfileRow(
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFF64748B),
                  iconBackground: const Color(0xFFF1F5F9),
                  title: l10n.profilePaymentHistory,
                  trailing: const ProfileTrailingValue(
                    badge: ProfilePillBadge(
                      label: '0',
                      background: Color(0xFFFEF9C3),
                      textColor: Color(0xFFB45309),
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ],
          ProfileSectionLabel(text: l10n.profileSectionNotifications),
          ProfileGroupCard(
            children: [
              ProfileRow(
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFFD97706),
                iconBackground: const Color(0xFFFEF9C3),
                title: l10n.profilePushNotifications,
                trailing: ProfileToggle(
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
              ),
              ProfileRow(
                icon: Icons.star_outline_rounded,
                iconColor: const Color(0xFF22C55E),
                iconBackground: const Color(0xFFF0FDF4),
                title: l10n.profileStreakReminder,
                subtitle: l10n.profileStreakReminderTime,
                trailing: ProfileToggle(
                  value: _streakReminder,
                  onChanged: (v) => setState(() => _streakReminder = v),
                ),
              ),
            ],
          ),
          ProfileSectionLabel(text: l10n.profileSectionApp),
          ProfileGroupCard(
            children: [
              ProfileRow(
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF0EA5E9),
                iconBackground: const Color(0xFFEFF9FF),
                title: l10n.settingsLanguageTitle,
                subtitle: currentLanguageLabel,
                trailing: const ProfileTrailingValue(),
                onTap: () => LanguagePickerSheet.show(context),
              ),
              ProfileRow(
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF64748B),
                iconBackground: const Color(0xFFF1F5F9),
                title: l10n.profilePrivacyPolicy,
                trailing: const ProfileTrailingValue(),
                onTap: _openPrivacyPolicy,
              ),
              ProfileRow(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF64748B),
                iconBackground: const Color(0xFFF1F5F9),
                title: l10n.profileVersionLabel,
                trailing: ProfileTrailingValue(
                  value: _appVersion == null ? '' : 'v$_appVersion',
                  showChevron: false,
                ),
              ),
            ],
          ),
          ProfileSectionLabel(text: l10n.profileSectionOther),
          ProfileGroupCard(
            children: [
              ProfileRow(
                icon: Icons.logout_rounded,
                iconColor: const Color(0xFFEF4444),
                iconBackground: const Color(0xFFFFF1F2),
                title: l10n.profileLogout,
                titleColor: const Color(0xFFEF4444),
                trailing: const ProfileTrailingValue(
                  chevronColor: Color(0xFFEF4444),
                ),
                onTap: _logout,
              ),
              ProfileRow(
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFEF4444),
                iconBackground: const Color(0xFFFFF1F2),
                title: l10n.profileDeleteAccount,
                subtitle: l10n.profileDeleteAccountWarning,
                titleColor: const Color(0xFFEF4444),
                trailing: const ProfileTrailingValue(
                  chevronColor: Color(0xFFEF4444),
                ),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _uzMonthsGenitive = [
  'yanvargacha',
  'fevralgacha',
  'martgacha',
  'aprelgacha',
  'maygacha',
  'iyungacha',
  'iyulgacha',
  'avgustgacha',
  'sentabrgacha',
  'oktabrgacha',
  'noyabrgacha',
  'dekabrgacha',
];

const _enMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _subscriptionSubtitle(
  AppLocalizations l10n,
  Locale locale,
  DateTime endDate,
) {
  final now = DateTime.now();
  final endLocal = endDate.toLocal();
  final daysLeft = endLocal
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
  final isEnglish = locale.languageCode == 'en';
  final dateLabel = isEnglish
      ? '${_enMonths[endLocal.month - 1]} ${endLocal.day}'
      : '${endLocal.day}-${_uzMonthsGenitive[endLocal.month - 1]}';
  return daysLeft > 0
      ? l10n.profileSubscriptionActive(dateLabel, daysLeft)
      : l10n.profileSubscriptionExpired(dateLabel);
}
