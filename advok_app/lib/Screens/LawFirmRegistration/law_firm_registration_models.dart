/// Firm profile details collected by step 1 of the law-firm registration
/// flow and passed forward to step 2.
class LawFirmRegistrationData {
  const LawFirmRegistrationData({
    required this.firmName,
    required this.foundedYear,
    required this.contactPersonName,
    this.logoFileName,
    required this.officialEmail,
    required this.mainPhone,
    this.receptionNumber,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.zipCode,
    required this.state,
  });

  final String firmName;
  final String foundedYear;
  final String contactPersonName;
  final String? logoFileName;
  final String officialEmail;
  final String mainPhone;
  final String? receptionNumber;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String zipCode;
  final String state;
}

/// A lawyer added in step 2 of the law-firm registration flow.
class FirmLawyer {
  const FirmLawyer({
    required this.fullName,
    this.phoneNumber,
    this.barLicense,
    this.yearsExperience,
    this.designation,
    this.expertise = const [],
  });

  final String fullName;
  final String? phoneNumber;
  final String? barLicense;
  final String? yearsExperience;
  final String? designation;
  final List<String> expertise;
}
