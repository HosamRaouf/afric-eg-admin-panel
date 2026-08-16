/// Venue details stored in `config/congress.venue`.
class Venue {
  final String name;
  final String address;
  final String mapsUrl;

  const Venue({
    required this.name,
    required this.address,
    required this.mapsUrl,
  });

  factory Venue.fromJson(Map<String, dynamic> json) => Venue(
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    mapsUrl: json['mapsUrl'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'mapsUrl': mapsUrl,
  };
}
