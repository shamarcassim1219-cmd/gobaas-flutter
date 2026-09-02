import 'api_client.dart';

class MyReview {
  final String id;
  final String orderId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  MyReview({
    required this.id,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory MyReview.fromJson(Map<String, dynamic> json) {
    return MyReview(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Confirmed against the real backend: POST /api/reviews with
/// {orderId, rating, comment} - the backend looks up the order
/// itself to find which Baas to attach the review to, so no
/// professionalId is needed here. Also enforces one review per
/// order server-side (409 if already reviewed), matching
/// OrdersScreen's own client-side limit. GET /api/reviews/mine
/// returns only reviews this account has actually submitted - used
/// for a "My Reviews" list distinct from the general Orders list.
class ReviewService {
  ReviewService._internal();
  static final ReviewService instance = ReviewService._internal();

  final _api = ApiClient.instance;

  Future<void> submitReview({
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    await _api.post('/api/reviews', body: {
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<List<MyReview>> myReviews() async {
    final data = await _api.get('/api/reviews/mine');
    final list = (data['reviews'] as List?) ?? [];
    return list.map((e) => MyReview.fromJson(e as Map<String, dynamic>)).toList();
  }
}
