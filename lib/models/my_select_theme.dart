class MySelectTheme {
  final int index;
  final String name;

  const MySelectTheme({required this.index, required this.name});

  Map<String, dynamic> toMap() => {
    'index': index,
    'name': name,
  };

  factory MySelectTheme.fromMap(Map<String, dynamic> data) => MySelectTheme(
    index: data['index'] ?? 0,
    name: data['name'] ?? '自由枠${data['index'] + 1}',
  );
}
