class Bird {
  final String commonName;
  final String scientificName;
  final String imageUrl;
  final String size;
  final String habitat;
  final String diet;
  final String conservationStatus;
  bool collected;

  Bird({
    required this.commonName,
    required this.scientificName,
    required this.imageUrl,
    required this.size,
    required this.habitat,
    required this.diet,
    required this.conservationStatus,
    this.collected = false,
  });

  factory Bird.fromJson(Map<String, dynamic> json) {
    return Bird(
      commonName: json['commonName'],
      scientificName: json['scientificName'],
      imageUrl: json['imageUrl'],
      size: json['size'],
      habitat: json['habitat'],
      diet: json['diet'],
      conservationStatus: json['conservationStatus'],
      collected: json['collected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commonName': commonName,
      'scientificName': scientificName,
      'imageUrl': imageUrl,
      'size': size,
      'habitat': habitat,
      'diet': diet,
      'conservationStatus': conservationStatus,
      'collected': collected,
    };
  }
}
