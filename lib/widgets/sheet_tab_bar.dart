import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/sheet_definitions.dart';
import '../providers/sheet_provider.dart';
import '../providers/tiles_provider.dart';

class SheetTabBar extends ConsumerWidget {
  const SheetTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSheetId = ref.watch(currentSheetProvider);

    return Container(
      color: const Color(0xFF0A0A1A),
      child: Row(
        children: kDefaultSheets.map((sheet) {
          final isSelected = sheet.id == currentSheetId;
          final isLocked = sheet.id == 'advance';
          final completedCount = ref.watch(completedCountProvider(sheet.id));

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isLocked) {
                  ref.read(currentSheetProvider.notifier).state = sheet.id;
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
                    if (isLocked)
                      const Icon(Icons.lock_outline, color: Colors.white24, size: 14)
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
                    Text(
                      sheet.name,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF00B4D8)
                            : isLocked
                                ? Colors.white24
                                : Colors.white54,
                        fontSize: 12,
                      ),
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
