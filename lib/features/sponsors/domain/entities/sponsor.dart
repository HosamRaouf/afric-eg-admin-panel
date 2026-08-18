/// Mirror of `sponsors/{id}` — the home screen sponsor marquee.
class Sponsor {
  final String id;
  final String name;
  final String image;
  final String url;

  const Sponsor({
    required this.id,
    required this.name,
    this.image = '',
    this.url = '',
  });

  factory Sponsor.fromJson(Map<String, dynamic> json, {String? id}) {
    return Sponsor(
      id: id ?? json['id'] as String? ?? json['__id__'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'url': url,
      };
}
