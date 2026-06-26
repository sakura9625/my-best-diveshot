class BestPhoto {
  final String fileName;
  final String subjectName;
  final String title;
  final String location;
  final DateTime? divingMonth;
  final String comment;
  final DateTime registeredAt;

  const BestPhoto({
    required this.fileName,
    required this.subjectName,
    required this.title,
    required this.location,
    this.divingMonth,
    required this.comment,
    required this.registeredAt,
  });

  Map<String, dynamic> toMap() => {
    'fileName': fileName,
    'subjectName': subjectName,
    'title': title,
    'location': location,
    'divingMonth': divingMonth?.toIso8601String(),
    'comment': comment,
    'registeredAt': registeredAt.toIso8601String(),
  };

  factory BestPhoto.fromMap(Map<String, dynamic> data) => BestPhoto(
    fileName: _extractFileName(
      data['fileName'] ?? data['localImagePath'] ?? '',
    ),
    subjectName: data['subjectName'] ?? '',
    title: data['title'] ?? '',
    location: data['location'] ?? '',
    divingMonth: data['divingMonth'] != null
        ? DateTime.parse(data['divingMonth'])
        : null,
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
}
