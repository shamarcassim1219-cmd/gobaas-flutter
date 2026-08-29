import 'api_client.dart';

/// NOTE: endpoint path/payload inferred from how reviews are shown
/// elsewhere in this project - Professional.reviewList suggests
/// reviews are stored against the professional, not nested under
/// the order, so this posts to the professional's own endpoint with
/// the order id in the body (to tie the review back to a specific
/// completed job). Not independently re-verified against the
/// backend in this session - if this also 404s, that's strong
/// evidence review submission isn't built on the backend yet rather
/// than just a wrong path guess.
class ReviewService {
  ReviewService._internal();
  static final ReviewService instance = ReviewService._internal();

  final _api = ApiClient.instance;

  Future<void> submitReview({
    required String professionalId,
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    await _api.post('/api/professionals/$professionalId/reviews', body: {
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
    });
  }
}
