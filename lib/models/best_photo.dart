class BestPhoto {
  final String localImagePath;
  final String subjectName;
  final String title;
  final String location;
  final DateTime? divingMonth;
  final String comment;
  final DateTime registeredAt;

  const BestPhoto({
    required this.localImagePath,
    required this.subjectName,
    required this.title,
    required this.location,
    this.divingMonth,
    required this.comment,
    required this.registeredAt,
  });

  Map<String, dynamic> toMap() => {
    'localImagePath': localImagePath,
    'subjectName': subjectName,
    'title': title,
    'location': location,
    'divingMonth': divingMonth?.toIso8601String(),
    'comment': comment,
    'registeredAt': registeredAt.toIso8601String(),
  };

  factory BestPhoto.fromMap(Map<String, dynamic> data) => BestPhoto(
    localImagePath: data['localImagePath'] ?? '',
    subjectName: data['subjectName'] ?? '',
    title: data['title'] ?? '',
    location: data['location'] ?? '',
    divingMonth: data['divingMonth'] != null ? DateTime.parse(data['divingMonth']) : null,
    comment: data['comment'] ?? '',
    registeredAt: data['registeredAt'] != null
        ? DateTime.parse(data['registeredAt'])
        : DateTime.now(),
  );
}
