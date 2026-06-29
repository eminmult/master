class MasterReview {
  const MasterReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.reviewerName,
    required this.reviewerAvatar,
    required this.photos,
  });

  final int id;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final String reviewerName;
  final String? reviewerAvatar;
  final List<String> photos;

  factory MasterReview.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'];
    final reviewerMap =
        reviewer is Map<String, dynamic> ? reviewer : const <String, dynamic>{};

    final photosRaw = json['photos'];
    final photos = photosRaw is List
        ? photosRaw
            .map((e) {
              if (e is String) return e;
              if (e is Map<String, dynamic>) {
                return (e['url'] ?? e['path'] ?? '').toString();
              }
              return '';
            })
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];

    int toInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return MasterReview(
      id: toInt(json['id']),
      rating: toInt(json['rating']),
      comment: json['comment']?.toString(),
      createdAt: switch (json['created_at']) {
        final String s when s.isNotEmpty => DateTime.tryParse(s),
        _ => null,
      },
      reviewerName: (reviewerMap['full_name'] ??
              reviewerMap['first_name'] ??
              'Аноним')
          .toString(),
      reviewerAvatar: reviewerMap['avatar_url']?.toString(),
      photos: photos,
    );
  }
}
