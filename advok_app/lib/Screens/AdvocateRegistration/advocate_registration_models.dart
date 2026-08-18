import '../../Utils/CountryData/country_catalog.dart';

enum AdvocateType { junior, senior }

extension AdvocateTypeLabel on AdvocateType {
  /// Country-aware title: Junior/Senior Advocate (India) or
  /// Associate/Senior Attorney (US).
  String get label => this == AdvocateType.junior
      ? CountryCatalog.terms.juniorTitle
      : CountryCatalog.terms.seniorTitle;
}

/// One US state bar admission: which state bar, the bar number issued by it,
/// and the current license status with that bar.
class BarAdmission {
  BarAdmission({
    required this.state,
    required this.barNumber,
    required this.licenseStatus,
  });

  final String state;
  final String barNumber;
  final String licenseStatus;

  Map<String, String> toJson() => {
        'state': state,
        'barNumber': barNumber,
        'licenseStatus': licenseStatus,
      };
}

/// Aggregates the data collected across the 5 advocate registration steps so
/// the final step can submit everything to the backend in one payload.
class AdvocateOnboardingData {
  AdvocateOnboardingData._();

  static final AdvocateOnboardingData current = AdvocateOnboardingData._();

  AdvocateType? advocateType;

  /// US-only classification (empty for countries with the Junior/Senior
  /// tier cards): "0–2 years" … "20+ years" and Partner/Associate/etc.
  String yearsInPractice = '';
  String firmRole = '';

  List<String> purposes = [];
  /// Profile photo as a base64 data URL ('' if the user skipped it).
  String photo = '';

  String state = '';
  String district = '';
  String officeAddress = '';
  String fullName = '';
  String seniorAdvocateName = '';
  String email = '';
  /// Bar Registration Number (India) / State Bar License (US).
  String licenseNumber = '';
  String primaryCourt = '';
  String practiceArea = '';

  /// US-only: state bar admissions (state + bar number + license status) and
  /// optional federal court admissions. Empty for other countries.
  List<BarAdmission> barAdmissions = [];
  List<String> federalCourtAdmissions = [];
  List<String> workingDays = [];
  String startTime = '';
  String endTime = '';

  void reset() {
    advocateType = null;
    yearsInPractice = '';
    firmRole = '';
    photo = '';
    purposes = [];
    state = '';
    district = '';
    officeAddress = '';
    fullName = '';
    seniorAdvocateName = '';
    email = '';
    licenseNumber = '';
    primaryCourt = '';
    practiceArea = '';
    barAdmissions = [];
    federalCourtAdmissions = [];
    workingDays = [];
    startTime = '';
    endTime = '';
  }

  Map<String, dynamic> toPayload() {
    return {
      'country': CountryCatalog.selected.name,
      'advocateType':
          advocateType == AdvocateType.senior ? 'senior' : 'junior',
      if (yearsInPractice.isNotEmpty) 'yearsInPractice': yearsInPractice,
      if (firmRole.isNotEmpty) 'firmRole': firmRole,
      if (photo.isNotEmpty) 'photo': photo,
      'purposes': purposes,
      'location': {
        'state': state,
        'district': district,
        'officeAddress': officeAddress,
      },
      'professional': {
        'fullName': fullName,
        if (seniorAdvocateName.isNotEmpty)
          'seniorAdvocateName': seniorAdvocateName,
        'email': email,
        'licenseNumber': licenseNumber,
        'primaryCourt': primaryCourt,
        'practiceArea': practiceArea.isEmpty ? 'General Practice' : practiceArea,
        if (barAdmissions.isNotEmpty)
          'barAdmissions': barAdmissions.map((a) => a.toJson()).toList(),
        if (federalCourtAdmissions.isNotEmpty)
          'federalCourtAdmissions': federalCourtAdmissions,
      },
      'schedule': {
        'workingDays': workingDays,
        'startTime': startTime,
        'endTime': endTime,
      },
    };
  }
}
