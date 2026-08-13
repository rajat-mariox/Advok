/// Country-specific legal-system wording and options used across the app.
///
/// The defaults describe the Indian system ("Advocate", Bar Council, Indian
/// courts). Countries with a different legal system (currently the US)
/// override the relevant fields, so the same screens render the right
/// terminology and pickers everywhere.
class LegalTerms {
  const LegalTerms({
    this.lawyerSingular = 'Advocate',
    this.lawyerPlural = 'Advocates',
    this.juniorTitle = 'Junior Advocate',
    this.juniorSubtitle = 'Less than 10 years of practice',
    this.juniorNote = 'You will be guided by senior advocates',
    this.seniorTitle = 'Senior Advocate',
    this.seniorSubtitle = '10+ years of practice',
    this.seniorNote = 'Designated by the High Court or Supreme Court',
    this.mentorFieldLabel = 'Senior Advocate Name',
    this.mentorRequiredForJunior = true,
    this.licenseLabel = 'Bar Registration Number',
    this.courts = const [
      'Supreme Court',
      'High Court',
      'District Court',
      'Family Court',
      'Consumer Court',
      'Tribunal',
    ],
    this.practiceAreaHint = 'e.g. Civil, Criminal, Family, Property',
    this.practiceAreas = const [
      'Criminal Law',
      'Civil Law',
      'Family Law',
      'Property Law',
      'Corporate Law',
      'Consumer Law',
      'Labour Law',
      'Immigration Law',
      'Cyber Law',
    ],
    this.verificationAuthority = 'Bar Council records',
    this.degreeHint = 'e.g. LLB, LLM',
    this.usesFirmRoles = false,
    this.yearsInPracticeOptions = const [],
    this.firmRoles = const [],
  });

  /// US legal system: "Attorney", per-state bar licensing, US court structure.
  static const LegalTerms us = LegalTerms(
    lawyerSingular: 'Attorney',
    lawyerPlural: 'Attorneys',
    juniorTitle: 'Associate Attorney',
    juniorSubtitle: 'Less than 10 years of practice',
    juniorNote: 'Works with a supervising attorney or firm',
    seniorTitle: 'Senior Attorney',
    seniorSubtitle: '10+ years of practice',
    seniorNote: 'Solo practitioner, partner, or of counsel',
    mentorFieldLabel: 'Supervising Attorney Name',
    mentorRequiredForJunior: false,
    licenseLabel: 'State Bar License',
    courts: [
      'State Trial Court',
      'State Appellate Court',
      'State Supreme Court',
      'Federal District Court',
      'Federal Court of Appeals',
      'Family Court',
      'Bankruptcy Court',
      'Immigration Court',
    ],
    practiceAreaHint: 'e.g. Personal Injury, Immigration, Family Law',
    practiceAreas: [
      'Criminal Defense',
      'Family Law',
      'Personal Injury',
      'Immigration',
      'Employment Law',
      'Real Estate',
      'Corporate/Business Law',
      'Bankruptcy',
      'Estate Planning',
      'Intellectual Property',
      'Tax Law',
      'Civil Litigation',
      'Cyber Law',
    ],
    verificationAuthority: 'state bar records',
    degreeHint: 'e.g. J.D., LL.M.',
    usesFirmRoles: true,
    yearsInPracticeOptions: [
      '0–2 years',
      '3–5 years',
      '6–10 years',
      '11–20 years',
      '20+ years',
    ],
    firmRoles: [
      'Partner',
      'Associate',
      'Senior Associate',
      'Of Counsel',
      'Counsel',
      'Staff Attorney',
      'Solo Practitioner',
    ],
  );

  final String lawyerSingular;
  final String lawyerPlural;

  /// Titles/notes for the two experience tiers on the Describe Yourself step.
  final String juniorTitle;
  final String juniorSubtitle;
  final String juniorNote;
  final String seniorTitle;
  final String seniorSubtitle;
  final String seniorNote;

  /// Mentor/senior field on the professional-details form. In India a junior
  /// must name their senior advocate; in the US it is optional.
  final String mentorFieldLabel;
  final bool mentorRequiredForJunior;

  /// What the license number field is called locally.
  final String licenseLabel;

  final List<String> courts;
  final String practiceAreaHint;

  /// The fixed practice-area list for this country. Single source of truth:
  /// the onboarding/edit-profile dropdowns and the client home screen's
  /// Legal Categories tiles are both generated from it, so tapping a
  /// category matches attorneys exactly.
  final List<String> practiceAreas;

  /// Which authority credentials are checked against ("Bar Council records" /
  /// "state bar records") — used in verification/help copy.
  final String verificationAuthority;

  /// Hint for the law-student degree field.
  final String degreeHint;

  /// US-style classification: instead of the fixed Junior/Senior tier cards,
  /// the Describe Yourself step asks for Years in Practice + Firm Role.
  final bool usesFirmRoles;
  final List<String> yearsInPracticeOptions;
  final List<String> firmRoles;
}

/// Per-country data used across the app: phone number validation rules and
/// the list of states/provinces shown in address forms.
class CountryProfile {
  const CountryProfile({
    required this.name,
    required this.minDigits,
    required this.maxDigits,
    this.stateLabel = 'State',
    this.states = const [],
    this.legal = const LegalTerms(),
  });

  final String name;

  /// Valid national-number length (digits only, without the dial code).
  final int minDigits;
  final int maxDigits;

  /// What the first-level division is called locally (State/Province/…).
  final String stateLabel;
  final List<String> states;

  /// Legal-system terminology and options for this country.
  final LegalTerms legal;

  bool isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '').length;
    return digits >= minDigits && digits <= maxDigits;
  }

  String get phoneLengthHint => minDigits == maxDigits
      ? '$minDigits digits'
      : '$minDigits–$maxDigits digits';
}

class CountryCatalog {
  CountryCatalog._();

  static const CountryProfile _fallback = CountryProfile(
    name: 'Unknown',
    minDigits: 7,
    maxDigits: 15,
  );

  /// The country chosen on the Select Country screen. Set at login and used
  /// by the onboarding address forms.
  static CountryProfile selected = _fallback;

  /// Shorthand for the selected country's legal terminology.
  static LegalTerms get terms => selected.legal;

  static void select(String countryName) {
    selected = byName(countryName);
  }

  static CountryProfile byName(String countryName) {
    for (final profile in _profiles) {
      if (profile.name == countryName) return profile;
    }
    return _fallback;
  }

  static const List<CountryProfile> _profiles = [
    CountryProfile(
      name: 'United States',
      minDigits: 10,
      maxDigits: 10,
      legal: LegalTerms.us,
      states: [
        'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
        'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
        'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
        'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
        'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
        'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
        'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
        'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
        'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
        'West Virginia', 'Wisconsin', 'Wyoming',
      ],
    ),
    CountryProfile(
      name: 'United Kingdom',
      minDigits: 10,
      maxDigits: 11,
      stateLabel: 'Region',
      states: ['England', 'Scotland', 'Wales', 'Northern Ireland'],
    ),
    CountryProfile(
      name: 'Canada',
      minDigits: 10,
      maxDigits: 10,
      stateLabel: 'Province',
      states: [
        'Alberta', 'British Columbia', 'Manitoba', 'New Brunswick',
        'Newfoundland and Labrador', 'Northwest Territories', 'Nova Scotia',
        'Nunavut', 'Ontario', 'Prince Edward Island', 'Quebec',
        'Saskatchewan', 'Yukon',
      ],
    ),
    CountryProfile(
      name: 'Australia',
      minDigits: 9,
      maxDigits: 10,
      states: [
        'Australian Capital Territory', 'New South Wales',
        'Northern Territory', 'Queensland', 'South Australia', 'Tasmania',
        'Victoria', 'Western Australia',
      ],
    ),
    CountryProfile(
      name: 'India',
      minDigits: 10,
      maxDigits: 10,
      states: [
        'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar',
        'Chhattisgarh', 'Chandigarh', 'Delhi', 'Goa', 'Gujarat', 'Haryana',
        'Himachal Pradesh', 'Jammu & Kashmir', 'Jharkhand', 'Karnataka',
        'Kerala', 'Ladakh', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
        'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Puducherry', 'Punjab',
        'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
        'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
      ],
    ),
    CountryProfile(
      name: 'Germany',
      minDigits: 10,
      maxDigits: 11,
      states: [
        'Baden-Württemberg', 'Bavaria', 'Berlin', 'Brandenburg', 'Bremen',
        'Hamburg', 'Hesse', 'Lower Saxony', 'Mecklenburg-Vorpommern',
        'North Rhine-Westphalia', 'Rhineland-Palatinate', 'Saarland',
        'Saxony', 'Saxony-Anhalt', 'Schleswig-Holstein', 'Thuringia',
      ],
    ),
    CountryProfile(
      name: 'France',
      minDigits: 9,
      maxDigits: 10,
      stateLabel: 'Region',
      states: [
        'Auvergne-Rhône-Alpes', 'Bourgogne-Franche-Comté', 'Brittany',
        'Centre-Val de Loire', 'Corsica', 'Grand Est', 'Hauts-de-France',
        'Île-de-France', 'Normandy', 'Nouvelle-Aquitaine', 'Occitanie',
        'Pays de la Loire', "Provence-Alpes-Côte d'Azur",
      ],
    ),
    CountryProfile(
      name: 'UAE',
      minDigits: 9,
      maxDigits: 9,
      stateLabel: 'Emirate',
      states: [
        'Abu Dhabi', 'Ajman', 'Dubai', 'Fujairah', 'Ras Al Khaimah',
        'Sharjah', 'Umm Al Quwain',
      ],
    ),
    CountryProfile(
      name: 'Singapore',
      minDigits: 8,
      maxDigits: 8,
      stateLabel: 'Region',
      states: ['Central', 'East', 'North', 'North-East', 'West'],
    ),
    CountryProfile(
      name: 'Pakistan',
      minDigits: 10,
      maxDigits: 10,
      stateLabel: 'Province',
      states: [
        'Azad Jammu & Kashmir', 'Balochistan', 'Gilgit-Baltistan',
        'Islamabad Capital Territory', 'Khyber Pakhtunkhwa', 'Punjab',
        'Sindh',
      ],
    ),
    CountryProfile(
      name: 'Nigeria',
      minDigits: 10,
      maxDigits: 11,
      states: [
        'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa',
        'Benue', 'Borno', 'Cross River', 'Delta', 'Ebonyi', 'Edo', 'Ekiti',
        'Enugu', 'Federal Capital Territory', 'Gombe', 'Imo', 'Jigawa',
        'Kaduna', 'Kano', 'Katsina', 'Kebbi', 'Kogi', 'Kwara', 'Lagos',
        'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 'Plateau',
        'Rivers', 'Sokoto', 'Taraba', 'Yobe', 'Zamfara',
      ],
    ),
    CountryProfile(
      name: 'South Africa',
      minDigits: 9,
      maxDigits: 10,
      stateLabel: 'Province',
      states: [
        'Eastern Cape', 'Free State', 'Gauteng', 'KwaZulu-Natal', 'Limpopo',
        'Mpumalanga', 'North West', 'Northern Cape', 'Western Cape',
      ],
    ),
    CountryProfile(
      name: 'Brazil',
      minDigits: 10,
      maxDigits: 11,
      states: [
        'Acre', 'Alagoas', 'Amapá', 'Amazonas', 'Bahia', 'Ceará',
        'Distrito Federal', 'Espírito Santo', 'Goiás', 'Maranhão',
        'Mato Grosso', 'Mato Grosso do Sul', 'Minas Gerais', 'Pará',
        'Paraíba', 'Paraná', 'Pernambuco', 'Piauí', 'Rio de Janeiro',
        'Rio Grande do Norte', 'Rio Grande do Sul', 'Rondônia', 'Roraima',
        'Santa Catarina', 'São Paulo', 'Sergipe', 'Tocantins',
      ],
    ),
    CountryProfile(
      name: 'Mexico',
      minDigits: 10,
      maxDigits: 10,
      states: [
        'Aguascalientes', 'Baja California', 'Baja California Sur',
        'Campeche', 'Chiapas', 'Chihuahua', 'Coahuila', 'Colima',
        'Durango', 'Guanajuato', 'Guerrero', 'Hidalgo', 'Jalisco',
        'Mexico City', 'México', 'Michoacán', 'Morelos', 'Nayarit',
        'Nuevo León', 'Oaxaca', 'Puebla', 'Querétaro', 'Quintana Roo',
        'San Luis Potosí', 'Sinaloa', 'Sonora', 'Tabasco', 'Tamaulipas',
        'Tlaxcala', 'Veracruz', 'Yucatán', 'Zacatecas',
      ],
    ),
    CountryProfile(
      name: 'Japan',
      minDigits: 10,
      maxDigits: 11,
      stateLabel: 'Prefecture',
      states: [
        'Aichi', 'Akita', 'Aomori', 'Chiba', 'Ehime', 'Fukui', 'Fukuoka',
        'Fukushima', 'Gifu', 'Gunma', 'Hiroshima', 'Hokkaido', 'Hyogo',
        'Ibaraki', 'Ishikawa', 'Iwate', 'Kagawa', 'Kagoshima', 'Kanagawa',
        'Kochi', 'Kumamoto', 'Kyoto', 'Mie', 'Miyagi', 'Miyazaki', 'Nagano',
        'Nagasaki', 'Nara', 'Niigata', 'Oita', 'Okayama', 'Okinawa',
        'Osaka', 'Saga', 'Saitama', 'Shiga', 'Shimane', 'Shizuoka',
        'Tochigi', 'Tokushima', 'Tokyo', 'Tottori', 'Toyama', 'Wakayama',
        'Yamagata', 'Yamaguchi', 'Yamanashi',
      ],
    ),
    CountryProfile(
      name: 'South Korea',
      minDigits: 9,
      maxDigits: 11,
      stateLabel: 'Province',
      states: [
        'Busan', 'Chungcheongbuk-do', 'Chungcheongnam-do', 'Daegu',
        'Daejeon', 'Gangwon-do', 'Gwangju', 'Gyeonggi-do',
        'Gyeongsangbuk-do', 'Gyeongsangnam-do', 'Incheon', 'Jeju',
        'Jeollabuk-do', 'Jeollanam-do', 'Sejong', 'Seoul', 'Ulsan',
      ],
    ),
  ];
}
