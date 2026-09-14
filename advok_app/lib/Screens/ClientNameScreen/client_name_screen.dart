import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../Routes/app_routes.dart';
import '../../Services/api_service.dart';
import '../../Utils/AppColors/app_colors.dart';

/// Asked once, right after a new client picks their role (or on the next
/// login if they quit before answering). Saves the name to the client
/// profile and then opens the client home.
class ClientNameScreen extends StatefulWidget {
  const ClientNameScreen({super.key});

  @override
  State<ClientNameScreen> createState() => _ClientNameScreenState();
}

class _ClientNameScreenState extends State<ClientNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _submitting = false;

  String get _name => _nameController.text.trim();
  bool get _canContinue => _name.length >= 2 && !_submitting;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await ApiService.updateProfile({'fullName': _name});
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.clientHome, (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.white,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/bg_pattern.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          const Text(
                            'WELCOME TO ADVOK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                              letterSpacing: 3.06,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "What's your name?",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 35.2 / 24,
                              letterSpacing: -0.59,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'This is how attorneys and firms will see you. '
                            'You can change it later from your profile.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 20 / 14,
                              letterSpacing: -0.15,
                              color: AppColors.textGrey555,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Full name',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildNameField(),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: _buildContinueButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: BoxDecoration(
        color: AppColors.fillGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _name.isEmpty ? AppColors.borderGrey : AppColors.textPrimary,
          width: 1.4,
        ),
      ),
      child: Center(
        child: TextField(
          controller: _nameController,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (_canContinue) _continue();
          },
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.name,
          maxLength: 60,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.23,
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            isCollapsed: true,
            counterText: '',
            border: InputBorder.none,
            hintText: 'e.g. John Carter',
            hintStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.23,
              color: AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    final enabled = _canContinue;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.textPrimary, AppColors.gradientDarkEnd],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: enabled ? _continue : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _submitting ? 'Please wait…' : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.31,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset(
                    'assets/icons/ic_chevron_right.svg',
                    width: 18,
                    height: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
