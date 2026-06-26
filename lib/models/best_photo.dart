class BestPhoto {
  final String fileName;
  final String subjectName;
  final String title;
  final String location;
  final DateTime? divingMonth;
  final DateTime? shotDate;
  final DateTime? crownedAt;
  final int crownCount;
  final bool isRestored;
  final String comment;
  final DateTime registeredAt;

  const BestPhoto({
    required this.fileName,
    required this.subjectName,
    required this.title,
    required this.location,
    this.divingMonth,
    this.shotDate,
    this.crownedAt,
    this.crownCount = 0,
    this.isRestored = false,
    required this.comment,
    required this.registeredAt,
  });

  Map<String, dynamic> toMap() => {
    'fileName': fileName,
    'subjectName': subjectName,
    'title': title,
    'location': location,
    'divingMonth': divingMonth?.toIso8601String(),
    'shotDate': shotDate?.toIso8601String(),
    'crownedAt': crownedAt?.toIso8601String(),
    'crownCount': crownCount,
    'isRestored': isRestored,
    'comment': comment,
    'registeredAt': registeredAt.toIso8601String(),
  };

  factory BestPhoto.fromMap(Map<String, dynamic> data) => BestPhoto(
    fileName: _extractFileName(data['fileName'] ?? data['localImagePath'] ?? ''),
    subjectName: data['subjectName'] ?? '',
    title: data['title'] ?? '',
    location: data['location'] ?? '',
    divingMonth: data['divingMonth'] != null ? DateTime.parse(data['divingMonth']) : null,
    shotDate: data['shotDate'] != null ? DateTime.parse(data['shotDate']) : null,
    crownedAt: data['crownedAt'] != null ? DateTime.parse(data['crownedAt']) : null,
    crownCount: data['crownCount'] ?? 0,
    isRestored: data['isRestored'] ?? false,
    comment: data['comment'] ?? '',
    registeredAt: data['registeredAt'] != null
        ? DateTime.parse(data['registeredAt'])
        : DateTime.now(),
  );

  static String _extractFileName(String fileNameOrPath) {
    if (fileNameOrPath.contains('/')) {
      return fileNameOrPath.split('/').last;
    }
    return fileNameOrPath;
  }

  BestPhoto copyWith({
    String? fileName,
    String? subjectName,
    String? title,
    String? location,
    DateTime? divingMonth,
    DateTime? shotDate,
    DateTime? crownedAt,
    int? crownCount,
    bool? isRestored,
    String? comment,
    DateTime? registeredAt,
  }) => BestPhoto(
    fileName: fileName ?? this.fileName,
    subjectName: subjectName ?? this.subjectName,
    title: title ?? this.title,
    location: location ?? this.location,
    divingMonth: divingMonth ?? this.divingMonth,
    shotDate: shotDate ?? this.shotDate,
    crownedAt: crownedAt ?? this.crownedAt,
    crownCount: crownCount ?? this.crownCount,
    isRestored: isRestored ?? this.isRestored,
    comment: comment ?? this.comment,
    registeredAt: registeredAt ?? this.registeredAt,
  );
}
