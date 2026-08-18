/// Mirror of `committee_categories/{id}` — a category members are grouped by.
class CommitteeCategory {
  final String id;
  final String name;
  final int order;

  const CommitteeCategory({
    required this.id,
    required this.name,
    this.order = 0,
  });

  factory CommitteeCategory.fromJson(Map<String, dynamic> json, {String? id}) {
    return CommitteeCategory(
      id: id ?? json['id'] as String? ?? json['__id__'] as String? ?? '',
      name: json['name'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'order': order,
      };
}
