class CarouselImageFromView {
  final String id;
  final String? promo;

  CarouselImageFromView({ required this.id, this.promo });

  factory CarouselImageFromView.fromJson(Map<String, dynamic> json) {
    return CarouselImageFromView(
      id: json['id'].toString(),
      promo: json['promo'], // Será null si no hay promoción
    );
  }
}
