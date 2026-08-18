/// Mirror of `committee/{id}` — a member of the congress organizing committee.
class CommitteeMember {
  final String id;
  final String categoryId;
  final String image;
  final String name;
  final String role;
  final String description;

  const CommitteeMember({
    required this.id,
    this.categoryId = '',
    this.image = '',
    required this.name,
    required this.role,
    this.description = '',
  });

  factory CommitteeMember.fromJson(Map<String, dynamic> json, {String? id}) {
    return CommitteeMember(
      id: id ?? json['id'] as String? ?? json['__id__'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      image: json['image'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'image': image,
        'name': name,
        'role': role,
        'description': description,
      };
}
