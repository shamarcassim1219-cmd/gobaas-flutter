import 'api_client.dart';

/// NOTE: endpoint path/payload inferred from the general pattern of
/// order-scoped actions elsewhere in this project (accept/reject/
/// complete all live under /api/orders/{id}/...) - not
/// independently re-verified against the backend in this session.
/// If this 404s, that confirms the real endpoint and this should be
/// corrected.
class ReviewService {
  ReviewService._internal();
  static final ReviewService instance = ReviewService._internal();

  final _api = ApiClient.instance;

  Future<void> submitReview({
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    await _api.post('/api/orders/$orderId/review', body: {
      'rating': rating,
      'comment': comment,
    });
  }
}
