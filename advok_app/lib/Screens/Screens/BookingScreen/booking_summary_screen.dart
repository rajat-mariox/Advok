import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../CommonWidgets/circle_back_button.dart';
import '../../../Services/api_service.dart';
import '../../../Utils/AppColors/app_colors.dart';
import '../AdvocateListScreen/advocate_list_screen.dart';
import 'booking_confirmed_screen.dart';
import 'consultation_type_screen.dart';

class BookingSummaryScreen extends StatefulWidget {
  const BookingSummaryScreen({
    super.key,
    required this.advocate,
    required this.consultationType,
    required this.date,
    required this.dateLabel,
    required this.timeLabel,
  });

  final Advocate advocate;
  final ConsultationType consultationType;

  /// The appointment day picked on the previous step.
  final DateTime date;
  final String dateLabel;
  final String timeLabel;

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  static const double _platformFee = 5.0;
  static const double _taxRate = 0.085;

  bool _submitting = false;

  Advocate get advocate => widget.advocate;

  ConsultationType get consultationType => widget.consultationType;

  String get dateLabel => widget.dateLabel;

  String get timeLabel => widget.timeLabel;

  /// API value for the selected consultation format.
  String get _consultationKind => switch (consultationType.title) {
        'Office Visit' => 'office_visit',
        'Phone Call' => 'phone_call',
        _ => 'video_call',
      };

  String get _isoDate {
    final d = widget.date;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmBooking() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final booking = await ApiService.createBooking(
        advocateId: advocate.id,
        consultationType: _consultationKind,
        date: _isoDate,
        time: timeLabel,
        amount: double.parse(_total.toStringAsFixed(2)),
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingConfirmedScreen(
            advocateName: advocate.name,
            date: dateLabel,
            time: timeLabel,
            type: consultationType.title,
            amount: _money(_total),
            isPending: booking['status'] == 'pending',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  double get _consultationFee =>
      double.parse(consultationType.price.replaceAll(RegExp(r'[^\d.]'), ''));

  double get _tax => (_consultationFee + _platformFee) * _taxRate;

  double get _total => _consultationFee + _platformFee + _tax;

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.white,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _buildAdvocateCard(),
                    const SizedBox(height: 16),
                    _buildDetailsCard(),
                    const SizedBox(height: 16),
                    _buildPaymentCard(),
                    const SizedBox(height: 16),
                    _buildPaymentMethodCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.96),
            border: const Border(top: BorderSide(color: AppColors.borderGrey)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.textPrimary,
                        AppColors.gradientDarkEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      // TODO: Process the payment before confirming.
                      onTap: _submitting ? null : _confirmBooking,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _submitting
                            ? const [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                ),
                              ]
                            : [
                                SvgPicture.asset(
                                  'assets/icons/ic_check_circle_white.svg',
                                  width: 18,
                                  height: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Confirm & Pay ${_money(_total)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.31,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          CircleBackButton(),
          Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: -0.23,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildAdvocateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: advocate.photoBytes != null
                ? Image.memory(
                    advocate.photoBytes!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  )
                : advocate.image.isEmpty
                    ? InitialsAvatar(name: advocate.name, size: 56)
                    : Image.asset(
                        advocate.image,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                advocate.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.08,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                advocate.specialty,
                style: const TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: AppColors.textGrey555,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      decoration: _cardDecoration,
      child: Column(
        children: [
          _DetailRow(
            label: 'Consultation Type',
            value: consultationType.title,
          ),
          const _RowDivider(),
          _DetailRow(label: 'Date', value: dateLabel),
          const _RowDivider(),
          _DetailRow(label: 'Time', value: timeLabel),
          const _RowDivider(),
          const _DetailRow(label: 'Duration', value: '60 minutes'),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      decoration: _cardDecoration,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Payment Breakdown',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: -0.08,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const _RowDivider(),
          _FeeRow(label: 'Consultation fee', value: _money(_consultationFee)),
          const _RowDivider(),
          _FeeRow(label: 'Platform fee', value: _money(_platformFee)),
          const _RowDivider(),
          _FeeRow(label: 'Tax (8.5%)', value: _money(_tax)),
          const _RowDivider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    letterSpacing: -0.08,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _money(_total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 28 / 20,
                    letterSpacing: -0.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_card.svg',
                width: 20,
                height: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Add payment method',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                    letterSpacing: -0.15,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Choose how you want to pay',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.textGrey555,
                  ),
                ),
              ],
            ),
          ),
          SvgPicture.asset(
            'assets/icons/ic_chevron_right_grey.svg',
            width: 16,
            height: 16,
          ),
        ],
      ),
    );
  }

  static final BoxDecoration _cardDecoration = BoxDecoration(
    color: AppColors.fillGrey,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.borderGrey),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: AppColors.textGrey555,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: AppColors.textGrey555,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.15,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.divider);
  }
}
