class Review {
  final String name;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({required this.name, required this.rating, required this.comment, required this.createdAt});

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      name: json['name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class Professional {
  final String id;
  final String name;
  final String initials;
  final String service;
  final List<String> services;
  final String location;
  final double? distanceKm;
  final double? rating;
  final int reviews;
  final double price;
  final bool verified;
  final String about;
  final String profilePhoto;
  final int completedOrders;
  final List<Review> reviewList;

  Professional({
    required this.id,
    required this.name,
    required this.initials,
    required this.service,
    required this.services,
    required this.location,
    this.distanceKm,
    this.rating,
    required this.reviews,
    required this.price,
    required this.verified,
    required this.about,
    required this.profilePhoto,
    required this.completedOrders,
    required this.reviewList,
  });

  factory Professional.fromJson(Map<String, dynamic> json) {
    return Professional(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Baas',
      initials: json['initials'] as String? ?? 'B',
      service: json['service'] as String? ?? '',
      services: (json['services'] as List?)?.map((e) => e.toString()).toList() ?? [],
      location: json['location'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      verified: json['verified'] == true,
      about: json['about'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String? ?? '',
      completedOrders: (json['completedOrders'] as num?)?.toInt() ?? 0,
      reviewList: (json['reviewList'] as List?)
              ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
