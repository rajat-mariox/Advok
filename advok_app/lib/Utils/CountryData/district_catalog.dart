/// Districts (India) and major cities (US) per state, used to suggest a
/// District / City while the user types in the onboarding address forms.
/// These are suggestions only — free text is always allowed.
class DistrictCatalog {
  DistrictCatalog._();

  /// Suggestions for [state] of [country]; empty if we have no data.
  static List<String> forState(String country, String state) =>
      _data[country]?[state] ?? const [];

  /// [forState] filtered by what the user has typed so far.
  static List<String> search(String country, String state, String query) {
    final all = forState(country, state);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final d in all)
        if (d.toLowerCase().contains(q)) d,
    ];
  }

  static const Map<String, Map<String, List<String>>> _data = {
    'India': {
      'Andhra Pradesh': [
        'Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool',
        'Kakinada', 'Rajahmundry', 'Tirupati', 'Anantapur', 'Kadapa',
      ],
      'Arunachal Pradesh': [
        'Itanagar', 'Naharlagun', 'Pasighat', 'Tawang', 'Ziro', 'Bomdila',
      ],
      'Assam': [
        'Guwahati', 'Dibrugarh', 'Silchar', 'Jorhat', 'Nagaon', 'Tezpur',
        'Tinsukia', 'Barpeta',
      ],
      'Bihar': [
        'Patna', 'Gaya', 'Muzaffarpur', 'Bhagalpur', 'Darbhanga', 'Purnia',
        'Ara', 'Begusarai', 'Chhapra',
      ],
      'Chhattisgarh': [
        'Raipur', 'Bilaspur', 'Durg', 'Bhilai', 'Korba', 'Raigarh',
        'Rajnandgaon', 'Jagdalpur',
      ],
      'Chandigarh': ['Chandigarh'],
      'Delhi': [
        'New Delhi', 'Central Delhi', 'North Delhi', 'South Delhi',
        'East Delhi', 'West Delhi', 'Dwarka', 'Rohini', 'Saket',
        'Karkardooma',
      ],
      'Goa': ['Panaji', 'Margao', 'Mapusa', 'Vasco da Gama', 'Ponda'],
      'Gujarat': [
        'Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar',
        'Gandhinagar', 'Junagadh', 'Anand', 'Mehsana',
      ],
      'Haryana': [
        'Gurugram', 'Faridabad', 'Panipat', 'Ambala', 'Hisar', 'Karnal',
        'Rohtak', 'Sonipat', 'Panchkula',
      ],
      'Himachal Pradesh': [
        'Shimla', 'Mandi', 'Dharamshala', 'Solan', 'Kullu', 'Una',
        'Hamirpur', 'Bilaspur',
      ],
      'Jammu & Kashmir': [
        'Srinagar', 'Jammu', 'Anantnag', 'Baramulla', 'Udhampur', 'Kathua',
        'Pulwama',
      ],
      'Jharkhand': [
        'Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Hazaribagh',
        'Deoghar', 'Giridih',
      ],
      'Karnataka': [
        'Bengaluru Urban', 'Mysuru', 'Mangaluru', 'Hubballi-Dharwad',
        'Belagavi', 'Kalaburagi', 'Shivamogga', 'Tumakuru', 'Ballari',
        'Udupi',
      ],
      'Kerala': [
        'Thiruvananthapuram', 'Ernakulam', 'Kozhikode', 'Thrissur',
        'Kollam', 'Kannur', 'Alappuzha', 'Kottayam', 'Palakkad',
        'Malappuram',
      ],
      'Ladakh': ['Leh', 'Kargil'],
      'Madhya Pradesh': [
        'Bhopal', 'Indore', 'Gwalior', 'Jabalpur', 'Ujjain', 'Sagar',
        'Rewa', 'Satna', 'Ratlam',
      ],
      'Maharashtra': [
        'Mumbai City', 'Mumbai Suburban', 'Pune', 'Nagpur', 'Thane',
        'Nashik', 'Chhatrapati Sambhajinagar', 'Solapur', 'Kolhapur',
        'Amravati', 'Navi Mumbai',
      ],
      'Manipur': [
        'Imphal West', 'Imphal East', 'Thoubal', 'Bishnupur',
        'Churachandpur',
      ],
      'Meghalaya': ['Shillong', 'Tura', 'Jowai', 'Nongpoh'],
      'Mizoram': ['Aizawl', 'Lunglei', 'Champhai', 'Serchhip'],
      'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung', 'Tuensang'],
      'Odisha': [
        'Bhubaneswar', 'Cuttack', 'Rourkela', 'Berhampur', 'Sambalpur',
        'Puri', 'Balasore',
      ],
      'Puducherry': ['Puducherry', 'Karaikal', 'Mahe', 'Yanam'],
      'Punjab': [
        'Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda',
        'Mohali', 'Hoshiarpur', 'Pathankot',
      ],
      'Rajasthan': [
        'Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Ajmer', 'Bikaner',
        'Alwar', 'Bhilwara', 'Sikar',
      ],
      'Sikkim': ['Gangtok', 'Namchi', 'Gyalshing', 'Mangan'],
      'Tamil Nadu': [
        'Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem',
        'Tirunelveli', 'Erode', 'Vellore', 'Thanjavur', 'Tiruppur',
      ],
      'Telangana': [
        'Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Khammam',
        'Rangareddy', 'Medchal-Malkajgiri',
      ],
      'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar'],
      'Uttar Pradesh': [
        'Lucknow', 'Kanpur', 'Ghaziabad', 'Noida', 'Varanasi', 'Prayagraj',
        'Agra', 'Meerut', 'Bareilly', 'Gorakhpur', 'Aligarh', 'Moradabad',
      ],
      'Uttarakhand': [
        'Dehradun', 'Haridwar', 'Nainital', 'Rudrapur', 'Almora',
        'Rishikesh',
      ],
      'West Bengal': [
        'Kolkata', 'Howrah', 'North 24 Parganas', 'South 24 Parganas',
        'Darjeeling', 'Siliguri', 'Durgapur', 'Asansol', 'Hooghly',
      ],
    },
    'United States': {
      'Alabama': [
        'Birmingham', 'Montgomery', 'Huntsville', 'Mobile', 'Tuscaloosa',
      ],
      'Alaska': ['Anchorage', 'Fairbanks', 'Juneau'],
      'Arizona': [
        'Phoenix', 'Tucson', 'Mesa', 'Scottsdale', 'Chandler', 'Tempe',
        'Flagstaff',
      ],
      'Arkansas': ['Little Rock', 'Fayetteville', 'Fort Smith', 'Springdale'],
      'California': [
        'Los Angeles', 'San Francisco', 'San Diego', 'San Jose',
        'Sacramento', 'Oakland', 'Fresno', 'Long Beach', 'Irvine',
        'Santa Clara',
      ],
      'Colorado': [
        'Denver', 'Colorado Springs', 'Aurora', 'Boulder', 'Fort Collins',
      ],
      'Connecticut': [
        'Hartford', 'New Haven', 'Stamford', 'Bridgeport', 'Norwalk',
      ],
      'Delaware': ['Wilmington', 'Dover', 'Newark'],
      'Florida': [
        'Miami', 'Orlando', 'Tampa', 'Jacksonville', 'Fort Lauderdale',
        'St. Petersburg', 'Tallahassee', 'West Palm Beach',
      ],
      'Georgia': [
        'Atlanta', 'Savannah', 'Augusta', 'Columbus', 'Macon', 'Athens',
      ],
      'Hawaii': ['Honolulu', 'Hilo', 'Kailua'],
      'Idaho': ['Boise', 'Meridian', 'Idaho Falls', "Coeur d'Alene"],
      'Illinois': [
        'Chicago', 'Aurora', 'Naperville', 'Springfield', 'Peoria',
        'Rockford', 'Evanston',
      ],
      'Indiana': [
        'Indianapolis', 'Fort Wayne', 'Evansville', 'South Bend', 'Carmel',
      ],
      'Iowa': ['Des Moines', 'Cedar Rapids', 'Davenport', 'Iowa City'],
      'Kansas': ['Wichita', 'Overland Park', 'Kansas City', 'Topeka'],
      'Kentucky': ['Louisville', 'Lexington', 'Bowling Green', 'Frankfort'],
      'Louisiana': [
        'New Orleans', 'Baton Rouge', 'Shreveport', 'Lafayette',
      ],
      'Maine': ['Portland', 'Augusta', 'Bangor'],
      'Maryland': [
        'Baltimore', 'Annapolis', 'Rockville', 'Silver Spring', 'Frederick',
      ],
      'Massachusetts': [
        'Boston', 'Cambridge', 'Worcester', 'Springfield', 'Lowell',
        'Quincy',
      ],
      'Michigan': [
        'Detroit', 'Grand Rapids', 'Ann Arbor', 'Lansing', 'Flint',
      ],
      'Minnesota': [
        'Minneapolis', 'St. Paul', 'Rochester', 'Duluth', 'Bloomington',
      ],
      'Mississippi': ['Jackson', 'Gulfport', 'Hattiesburg', 'Biloxi'],
      'Missouri': [
        'Kansas City', 'St. Louis', 'Springfield', 'Columbia',
        'Jefferson City',
      ],
      'Montana': ['Billings', 'Missoula', 'Bozeman', 'Helena'],
      'Nebraska': ['Omaha', 'Lincoln', 'Bellevue'],
      'Nevada': ['Las Vegas', 'Reno', 'Henderson', 'Carson City'],
      'New Hampshire': ['Manchester', 'Nashua', 'Concord'],
      'New Jersey': [
        'Newark', 'Jersey City', 'Trenton', 'Paterson', 'Edison',
        'Princeton',
      ],
      'New Mexico': ['Albuquerque', 'Santa Fe', 'Las Cruces'],
      'New York': [
        'Manhattan', 'Brooklyn', 'Queens', 'The Bronx', 'Staten Island',
        'Buffalo', 'Rochester', 'Albany', 'Syracuse', 'White Plains',
      ],
      'North Carolina': [
        'Charlotte', 'Raleigh', 'Durham', 'Greensboro', 'Winston-Salem',
        'Asheville',
      ],
      'North Dakota': ['Fargo', 'Bismarck', 'Grand Forks'],
      'Ohio': [
        'Columbus', 'Cleveland', 'Cincinnati', 'Toledo', 'Akron', 'Dayton',
      ],
      'Oklahoma': ['Oklahoma City', 'Tulsa', 'Norman', 'Edmond'],
      'Oregon': ['Portland', 'Salem', 'Eugene', 'Bend'],
      'Pennsylvania': [
        'Philadelphia', 'Pittsburgh', 'Harrisburg', 'Allentown', 'Erie',
        'Scranton',
      ],
      'Rhode Island': ['Providence', 'Warwick', 'Cranston'],
      'South Carolina': [
        'Charleston', 'Columbia', 'Greenville', 'Myrtle Beach',
      ],
      'South Dakota': ['Sioux Falls', 'Rapid City', 'Pierre'],
      'Tennessee': ['Nashville', 'Memphis', 'Knoxville', 'Chattanooga'],
      'Texas': [
        'Houston', 'Dallas', 'Austin', 'San Antonio', 'Fort Worth',
        'El Paso', 'Plano', 'Arlington', 'Corpus Christi', 'Frisco',
      ],
      'Utah': ['Salt Lake City', 'Provo', 'Ogden', 'St. George'],
      'Vermont': ['Burlington', 'Montpelier'],
      'Virginia': [
        'Virginia Beach', 'Richmond', 'Norfolk', 'Arlington', 'Alexandria',
        'Fairfax',
      ],
      'Washington': ['Seattle', 'Spokane', 'Tacoma', 'Bellevue', 'Olympia'],
      'West Virginia': ['Charleston', 'Huntington', 'Morgantown'],
      'Wisconsin': ['Milwaukee', 'Madison', 'Green Bay', 'Kenosha'],
      'Wyoming': ['Cheyenne', 'Casper', 'Jackson'],
    },
  };
}
