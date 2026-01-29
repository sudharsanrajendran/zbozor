class ItemCountModel {
  final int count;

  ItemCountModel({required this.count});

  factory ItemCountModel.fromJson(Map<String, dynamic> json) {
    return ItemCountModel(
      count: json['count'] ?? 0,
    );
  }
}
