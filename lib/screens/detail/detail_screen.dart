import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../constants/themes.dart';
import '../../models/tile_data.dart';
import '../../models/best_photo.dart';
import '../../providers/tiles_provider.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final ThemeDefinition theme;

  const DetailScreen({super.key, required this.theme});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _commentController;
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _locationController = TextEditingController();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _initControllers(BestPhoto photo) {
    _titleController.text = photo.title;
    _locationController.text = photo.location;
    _commentController.text = photo.comment;
    _selectedMonth = photo.divingMonth;
  }

  Future<void> _pickMonth(BuildContext context) async {
    int selectedYear = _selectedMonth?.year ?? DateTime.now().year;
    int selectedMonth = _selectedMonth?.month ?? DateTime.now().month;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('撮影月を選択', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            height: 200,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                          onPressed: () => setDialogState(() => selectedYear--),
                        ),
                        Text('$selectedYear年', style: const TextStyle(color: Colors.white, fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                          onPressed: () {
                            if (selectedYear < DateTime.now().year) {
                              setDialogState(() => selectedYear++);
                            }
                          },
                        ),
                      ],
                    ),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          final isSelected = month == selectedMonth;
                          return GestureDetector(
                            onTap: () => setDialogState(() => selectedMonth = month),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF00B4D8) : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$month月',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(selectedYear, selectedMonth);
                });
                Navigator.pop(context);
              },
              child: const Text('決定', style: TextStyle(color: Color(0xFF00B4D8))),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveEdits(TileData tile) async {
    final current = tile.currentBest!;
    final updated = BestPhoto(
      localImagePath: current.localImagePath,
      subjectName: '',
      title: _titleController.text,
      location: _locationController.text,
      divingMonth: _selectedMonth,
      comment: _commentController.text,
      registeredAt: current.registeredAt,
    );
    await ref.read(tilesProvider.notifier).updatePhotoMeta(widget.theme.id, updated);
    setState(() => _isEditing = false);
  }

  String _formatMonth(DateTime? date) {
    if (date == null) return '未入力';
    return DateFormat('yyyy年M月').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final tiles = ref.watch(tilesProvider);
    final tile = tiles[widget.theme.id];
    final hasPhoto = tile?.hasPhoto ?? false;
    final photo = tile?.currentBest;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.theme.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (hasPhoto && !_isEditing)
            TextButton(
              onPressed: () {
                _initControllers(photo!);
                setState(() => _isEditing = true);
              },
              child: const Text('編集', style: TextStyle(color: Color(0xFF00B4D8))),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () => _saveEdits(tile!),
              child: const Text('保存', style: TextStyle(color: Color(0xFF00B4D8))),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 写真エリア
            hasPhoto && photo != null
                ? AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.file(
                      File(photo.localImagePath),
                      fit: BoxFit.cover,
                    ),
                  )
                : AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      color: const Color(0xFF1A1A2E),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: Colors.white24, size: 56),
                          SizedBox(height: 12),
                          Text(
                            'まだ登録されていません',
                            style: TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
            // 王者を更新するボタン
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(tilesProvider.notifier).pickAndRegisterPhoto(widget.theme.id);
                },
                icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF00B4D8)),
                label: const Text('王者を更新する', style: TextStyle(color: Color(0xFF00B4D8))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00B4D8)),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 入力フィールド
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUnderlineField(
                    label: 'タイトル・生物名',
                    value: photo?.title ?? '',
                    controller: _titleController,
                    isEditing: _isEditing,
                    enabled: hasPhoto,
                    hint: '例：運命の出会い / アオウミガメ',
                  ),
                  const SizedBox(height: 20),
                  _buildUnderlineField(
                    label: '撮影場所',
                    value: photo?.location ?? '',
                    controller: _locationController,
                    isEditing: _isEditing,
                    enabled: hasPhoto,
                    hint: '例：石垣島 竜串',
                  ),
                  const SizedBox(height: 20),
                  _buildMonthField(context, photo, hasPhoto),
                  const SizedBox(height: 20),
                  _buildUnderlineField(
                    label: '思い出コメント',
                    value: photo?.comment ?? '',
                    controller: _commentController,
                    isEditing: _isEditing,
                    enabled: hasPhoto,
                    hint: '例：透明度30m、一生忘れられない一枚',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  // 歴代王者
                  const Text(
                    '歴代王者',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (tile == null || tile.history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'まだ歴代王者はいません',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    )
                  else
                    ...tile.history.reversed.map((h) => _buildHistoryItem(h)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnderlineField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    required bool enabled,
    String hint = '',
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white54 : Colors.white24,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        isEditing
            ? TextField(
                controller: controller,
                maxLines: maxLines,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.white24),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00B4D8)),
                  ),
                  filled: false,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enabled
                        ? (value.isEmpty ? hint : value)
                        : hint,
                    style: TextStyle(
                      color: (!enabled || value.isEmpty) ? Colors.white24 : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 1,
                    color: Colors.white12,
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildMonthField(BuildContext context, BestPhoto? photo, bool enabled) {
    final displayText = _isEditing
        ? _formatMonth(_selectedMonth)
        : _formatMonth(photo?.divingMonth);
    final isEmpty = photo?.divingMonth == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '撮影月',
          style: TextStyle(
            color: enabled ? Colors.white54 : Colors.white24,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        _isEditing
            ? GestureDetector(
                onTap: () => _pickMonth(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayText,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        const Spacer(),
                        const Icon(Icons.calendar_today, color: Colors.white38, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(height: 1, color: const Color(0xFF00B4D8)),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enabled ? displayText : '写真登録後に入力できます',
                    style: TextStyle(
                      color: (!enabled || isEmpty) ? Colors.white24 : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 1, color: Colors.white12),
                ],
              ),
      ],
    );
  }

  Widget _buildHistoryItem(BestPhoto photo) {
    final parts = [
      if (photo.title.isNotEmpty) photo.title,
      if (photo.location.isNotEmpty) photo.location,
      if (photo.divingMonth != null) _formatMonth(photo.divingMonth),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(photo.localImagePath),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: Colors.white12,
                child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              parts.isEmpty ? '情報なし' : parts.join(' / '),
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
