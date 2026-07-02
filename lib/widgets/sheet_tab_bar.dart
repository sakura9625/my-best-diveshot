import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/sheet_definitions.dart';
import '../providers/sheet_provider.dart';
import '../providers/tiles_provider.dart';
import '../providers/bingo_provider.dart';

class SheetTabBar extends ConsumerWidget {
  const SheetTabBar({super.key});

  void _showLockedDialog(BuildContext context, String requiredSheetName, int requiredBingos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('ロック中', style: TextStyle(color: Colors.white)),
        content: Text(
          'まだロックされています。$requiredSheetNameのビンゴを$requiredBingos個以上揃えると解放されます。',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00B4D8))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSheetId = ref.watch(currentSheetProvider);

    return Container(
      color: const Color(0xFF0A0A1A),
      child: Row(
        children: kDefaultSheets.map((sheet) {
          final isSelected = sheet.id == currentSheetId;
          final isUnlocked = ref.watch(sheetUnlockedProvider(sheet.id));
          final completedCount = ref.watch(completedCountProvider(sheet.id));
          final requiredSheetId = sheet.unlockRequiredSheetId ?? 'open_water';
          final requiredSheetName = kDefaultSheets.firstWhere((s) => s.id == requiredSheetId).name;
          final currentBingoCount = ref.watch(bingoCountProvider(requiredSheetId));
          final requiredBingos = sheet.unlockRequiredBingos ?? 3;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (isUnlocked) {
                  ref.read(currentSheetProvider.notifier).state = sheet.id;
                } else {
                  _showLockedDialog(context, requiredSheetName, requiredBingos);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? const Color(0xFF00B4D8) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isUnlocked)
                      Text(
                        '$currentBingoCount/$requiredBingos',
                        style: const TextStyle(color: Colors.white24, fontSize: 10),
                      )
                    else
                      Text(
                        '$completedCount/25',
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF00B4D8) : Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isUnlocked)
                          const Padding(
                            padding: EdgeInsets.only(right: 2),
                            child: Icon(Icons.lock_outline, color: Colors.white24, size: 10),
                          ),
                        Text(
                          sheet.name,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00B4D8)
                                : isUnlocked
                                    ? Colors.white54
                                    : Colors.white24,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
