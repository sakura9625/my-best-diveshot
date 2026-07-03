import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../constants/themes.dart';
import '../../models/tile_data.dart';
import '../../models/best_photo.dart';
import '../../providers/tiles_provider.dart';
import '../../widgets/resolved_image.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final ThemeDefinition theme;
  final int initialIndex;
  final String sheetId;
  final List<ThemeDefinition> themes;

  const DetailScreen({
    super.key,
    required this.theme,
    required this.initialIndex,
    required this.sheetId,
    required this.themes,
  });

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _commentController;
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _titleController = TextEditingController();
    _locationController = TextEditingController();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  ThemeDefinition get _currentTheme => widget.themes[_currentIndex];

  void _initControllers(BestPhoto photo) {
    _titleController.text = photo.title;
    _locationController.text = photo.location;
    _commentController.text = photo.comment;
    _selectedMonth = photo.divingMonth;
  }

  Future<void> _showImageSourcePicker(String themeId, {bool isProvisional = false}) async {
    if (isProvisional) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('注意', style: TextStyle(color: Colors.white)),
          content: const Text(
            '王者候補を更新すると、現在の仮登録写真は削除されます。\nよろしいですか？\n\n（王者認定すると別の写真に更新しても記録に残ります）',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('更新する', style: TextStyle(color: Color(0xFF00B4D8))),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    await ref.read(tilesProvider(widget.sheetId).notifier).pickAndRegisterPhoto(themeId);
  }

  Future<void> _pickMonth(BuildContext context) async {
    int selectedYear = _selectedMonth?.year ?? DateTime.now().year;
    int selectedMonth = _selectedMonth?.month ?? DateTime.now().month;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('撮影月を選択', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          height: 200,
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
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
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _selectedMonth = DateTime(selectedYear, selectedMonth));
              Navigator.pop(context);
            },
            child: const Text('決定', style: TextStyle(color: Color(0xFF00B4D8))),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEdits(TileData tile) async {
    final current = tile.currentBest!;
    final updated = BestPhoto(
      fileName: current.fileName,
      subjectName: '',
      title: _titleController.text,
      location: _locationController.text,
      divingMonth: _selectedMonth,
      comment: _commentController.text,
      registeredAt: current.registeredAt,
    );
    await ref.read(tilesProvider(widget.sheetId).notifier).updatePhotoMeta(_currentTheme.id, updated);
    setState(() => _isEditing = false);
  }

  String _formatMonth(DateTime? date) {
    if (date == null) return '未入力';
    return DateFormat('yyyy年M月').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.themes.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _isEditing = false;
          });
        },
        itemBuilder: (context, index) {
          final theme = widget.themes[index];
          final tiles = ref.watch(tilesProvider(widget.sheetId));
          final tile = tiles[theme.id];
          final hasPhoto = tile?.hasPhoto ?? false;
          final photo = tile?.currentBest;
          return _buildPage(context, theme, tile, hasPhoto, photo);
        },
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    ThemeDefinition theme,
    TileData? tile,
    bool hasPhoto,
    BestPhoto? photo,
  ) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF0A0A1A),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            theme.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          pinned: true,
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasPhoto && tile?.isProvisional == true)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '合格点なら王者認定しましょう',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref.read(tilesProvider(widget.sheetId).notifier).crownAsKing(theme.id);
                        },
                        icon: const Text('👑', style: TextStyle(fontSize: 16)),
                        label: const Text('王者に認定する'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: () {
                  if (tile?.isKing == true) {
                    ref.read(tilesProvider(widget.sheetId).notifier).updateKing(theme.id);
                  } else {
                    final isProvisional = tile?.isProvisional == true;
                    _showImageSourcePicker(theme.id, isProvisional: isProvisional);
                  }
                },
                child: hasPhoto && photo != null
                    ? AspectRatio(
                        aspectRatio: 4 / 3,
                        child: ResolvedImage(fileName: photo.fileName, fit: BoxFit.cover),
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
                              Text('タップして写真を登録', style: TextStyle(color: Colors.white38, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: OutlinedButton.icon(
                  onPressed: () {
                    final isProvisional = tile?.isProvisional == true;
                    _showImageSourcePicker(theme.id, isProvisional: isProvisional);
                  },
                  icon: const Icon(Icons.swap_horiz, color: Color(0xFF00B4D8), size: 18),
                  label: Text(
                    tile?.isKing == true ? '王者を更新する' : '王者候補を更新する',
                    style: const TextStyle(color: Color(0xFF00B4D8)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00B4D8)),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ),
              if (hasPhoto)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: OutlinedButton(
                    onPressed: () {
                      if (_isEditing) {
                        _saveEdits(tile!);
                      } else {
                        _initControllers(photo!);
                        setState(() => _isEditing = true);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      minimumSize: const Size(double.infinity, 36),
                    ),
                    child: Text(
                      _isEditing ? '保存' : '編集',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
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
                    const SizedBox(height: 28),
                    if (hasPhoto && photo != null)
                      _buildKingHistoryCard(photo, tile),
                    const SizedBox(height: 28),
                    const Text(
                      '歴代王者',
                      style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (tile == null || tile.history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('まだ歴代王者はいません', style: TextStyle(color: Colors.white24, fontSize: 13)),
                      )
                    else ...[
                      ...tile.history.asMap().entries.map((entry) =>
                          _buildHistoryItem(entry.value, entry.key, theme.id)),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _showCompareCarousel(tile),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          minimumSize: const Size(double.infinity, 36),
                        ),
                        child: const Text('歴代王者を比較する', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCompareCarousel(TileData tile) {
    final allPhotos = [
      if (tile.currentBest != null) tile.currentBest!,
      ...tile.history.reversed,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A1A),
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('歴代王者', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: PageView.builder(
                itemCount: allPhotos.length,
                itemBuilder: (context, index) {
                  final p = allPhotos[index];
                  final isCurrentKing = index == 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ResolvedImage(
                              fileName: p.fileName,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isCurrentKing ? '👑 現在の王者' : '歴代 ${index}代目',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        if (p.title.isNotEmpty)
                          Text(p.title, style: const TextStyle(color: Colors.white, fontSize: 15)),
                        Text(
                          [if (p.location.isNotEmpty) p.location, _formatMonth(p.divingMonth)].join(' / '),
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        if (!isCurrentKing) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {
                              final historyIndex = tile.history.length - index;
                              ref.read(tilesProvider(widget.sheetId).notifier).restoreFromHistory(
                                _currentTheme.id,
                                historyIndex,
                              );
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF00B4D8))),
                            child: const Text('復活させる', style: TextStyle(color: Color(0xFF00B4D8))),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
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
        Text(label, style: TextStyle(color: enabled ? Colors.white54 : Colors.white24, fontSize: 12)),
        const SizedBox(height: 4),
        isEditing
            ? TextField(
                controller: controller,
                maxLines: maxLines,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.white24),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00B4D8))),
                  filled: false,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enabled ? (value.isEmpty ? hint : value) : hint,
                    style: TextStyle(color: (!enabled || value.isEmpty) ? Colors.white24 : Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 1, color: Colors.white12),
                ],
              ),
      ],
    );
  }

  Widget _buildMonthField(BuildContext context, BestPhoto? photo, bool enabled) {
    final displayText = _isEditing ? _formatMonth(_selectedMonth) : _formatMonth(photo?.divingMonth);
    final isEmpty = photo?.divingMonth == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('撮影月', style: TextStyle(color: enabled ? Colors.white54 : Colors.white24, fontSize: 12)),
        const SizedBox(height: 4),
        _isEditing
            ? GestureDetector(
                onTap: () => _pickMonth(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(displayText, style: const TextStyle(color: Colors.white, fontSize: 15)),
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
                    style: TextStyle(color: (!enabled || isEmpty) ? Colors.white24 : Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 1, color: Colors.white12),
                ],
              ),
      ],
    );
  }

  Widget _buildKingHistoryCard(BestPhoto photo, TileData? tile) {
    final isKing = tile?.isKing ?? false;
    final now = DateTime.now();

    String message;
    if (!isKing) {
      message = '📸 仮登録中 - 王者に認定しましょう';
    } else if (photo.isRestored) {
      message = '👑 王者返り咲き！';
    } else if ((tile?.history ?? []).isEmpty) {
      message = '👑 新しい王者が誕生しました';
    } else {
      message = '👑 王者が交代しました';
    }

    final crownCountText = isKing && photo.crownCount > 0
        ? '${photo.crownCount}代目の王者'
        : null;

    String? daysFromShot;
    if (photo.shotDate != null) {
      final days = now.difference(photo.shotDate!).inDays;
      daysFromShot = '初撮影から $days 日';
    }

    String? reignDays;
    if (isKing && photo.crownedAt != null) {
      final days = now.difference(photo.crownedAt!).inDays;
      reignDays = '在任 $days 日';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isKing ? const Color(0xFF00B4D8).withOpacity(0.4) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: isKing ? const Color(0xFF00B4D8) : Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (crownCountText != null) ...[
            const SizedBox(height: 4),
            Text(crownCountText, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
          if (daysFromShot != null || reignDays != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (daysFromShot != null)
                  Text(daysFromShot, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                if (daysFromShot != null && reignDays != null)
                  const Text('　', style: TextStyle(color: Colors.white24)),
                if (reignDays != null)
                  Text(reignDays, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          if (photo.shotDate != null)
            _buildHistoryRow('撮影日', _formatDate(photo.shotDate)),
          if (isKing && photo.crownedAt != null)
            _buildHistoryRow('即位日', _formatDate(photo.crownedAt)),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Text('$label：', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '不明';
    return '${date.year}年${date.month}月${date.day}日';
  }

  Widget _buildHistoryItem(BestPhoto photo, int index, String themeId) {
    final parts = [
      if (photo.title.isNotEmpty) photo.title,
      if (photo.location.isNotEmpty) photo.location,
      if (photo.divingMonth != null) _formatMonth(photo.divingMonth),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: ResolvedImage(
              fileName: photo.fileName,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: Container(
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
          TextButton(
            onPressed: () {
              ref.read(tilesProvider(widget.sheetId).notifier).restoreFromHistory(themeId, index);
            },
            child: const Text('復活', style: TextStyle(color: Color(0xFF00B4D8), fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
