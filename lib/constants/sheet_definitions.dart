enum SheetType { openWater, advance, mySelect, extra }

class SheetDefinition {
  final String id;
  final String name;
  final SheetType type;
  final int order;
  final int? unlockRequiredBingos;
  final String? unlockRequiredSheetId; // どのシートのビンゴが必要か

  const SheetDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.order,
    this.unlockRequiredBingos,
    this.unlockRequiredSheetId,
  });
}

const kDefaultSheets = [
  SheetDefinition(id: 'open_water', name: 'Open Water', type: SheetType.openWater, order: 0),
  SheetDefinition(
    id: 'advance',
    name: 'Advanced',
    type: SheetType.advance,
    order: 1,
    unlockRequiredBingos: 3,
    unlockRequiredSheetId: 'open_water',
  ),
  SheetDefinition(
    id: 'my_select',
    name: 'My Select',
    type: SheetType.mySelect,
    order: 2,
    unlockRequiredBingos: 3,
    unlockRequiredSheetId: 'advance',
  ),
];

// 追加ビンゴシート定義（課金）
const kExtraSheets = [
  SheetDefinition(id: 'ishigaki', name: '石垣ビンゴ', type: SheetType.extra, order: 3),
  SheetDefinition(id: 'izu', name: '伊豆周辺ビンゴ', type: SheetType.extra, order: 4),
  SheetDefinition(id: 'kushimoto', name: '串本周辺ビンゴ', type: SheetType.extra, order: 5),
  SheetDefinition(id: 'kashiwajima', name: '柏島・愛南ビンゴ', type: SheetType.extra, order: 6),
  SheetDefinition(id: 'macro', name: 'マクロビンゴ', type: SheetType.extra, order: 7),
  SheetDefinition(id: 'wide', name: 'ワイドビンゴ', type: SheetType.extra, order: 8),
  SheetDefinition(id: 'deep', name: '深場・底地ビンゴ', type: SheetType.extra, order: 9),
  SheetDefinition(id: 'hanadi', name: 'ハナダイビンゴ', type: SheetType.extra, order: 10),
  SheetDefinition(id: 'nudibranch_iro', name: 'ウミウシビンゴ（イロウミウシ）', type: SheetType.extra, order: 11),
  SheetDefinition(id: 'nudibranch_other', name: 'ウミウシビンゴ（イロウミウシ以外）', type: SheetType.extra, order: 12),
  SheetDefinition(id: 'goby_bingo', name: 'ハゼビンゴ', type: SheetType.extra, order: 13),
  SheetDefinition(id: 'crustacean_standard', name: '甲殻類 定番', type: SheetType.extra, order: 14),
  SheetDefinition(id: 'crustacean_hidden', name: '甲殻類 意外と人気な地味子ちゃん', type: SheetType.extra, order: 15),
];
