import 'api_client.dart';

/// Confirmed against the real backend: POST /api/reviews with
/// {orderId, rating, comment} - the backend looks up the order
/// itself to find which Baas to attach the review to, so no
/// professionalId is needed here. Also enforces one review per
/// order server-side (409 if already reviewed), matching
/// OrdersScreen's own client-side limit.
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
}
