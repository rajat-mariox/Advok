enum AdvocateType { junior, senior }

extension AdvocateTypeLabel on AdvocateType {
  String get label =>
      this == AdvocateType.junior ? 'Junior Advocate' : 'Senior Advocate';
}

/// Aggregates the data collected across the 5 advocate registration steps so
/// the final step can submit everything to the backend in one payload.
class AdvocateOnboardingData {
  AdvocateOnboardingData._();

  static final AdvocateOnboardingData current = AdvocateOnboardingData._();

  AdvocateType? advocateType;
  List<String> purposes = [];
  String state = '';
  String district = '';
  String officeAddress = '';
  String fullName = '';
  String seniorAdvocateName = '';
  String email = '';
  String barRegistrationNumber = '';
  String primaryCourt = '';
  String practiceArea = '';
  List<String> workingDays = [];
  String startTime = '';
  String endTime = '';

  void reset() {
    advocateType = null;
    purposes = [];
    state = '';
    district = '';
    officeAddress = '';
    fullName = '';
    seniorAdvocateName = '';
    email = '';
    barRegistrationNumber = '';
    primaryCourt = '';
    practiceArea = '';
    workingDays = [];
    startTime = '';
    endTime = '';
  }

  Map<String, dynamic> toPayload() {
    return {
      'advocateType':
          advocateType == AdvocateType.senior ? 'senior' : 'junior',
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
        'barRegistrationNumber': barRegistrationNumber,
        'primaryCourt': primaryCourt,
        'practiceArea': practiceArea.isEmpty ? 'General Practice' : practiceArea,
      },
      'schedule': {
        'workingDays': workingDays,
        'startTime': startTime,
        'endTime': endTime,
      },
    };
  }
}
