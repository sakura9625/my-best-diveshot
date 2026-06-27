enum SheetType { openWater, advance, mySelect }

class SheetDefinition {
  final String id;
  final String name;
  final SheetType type;
  final int order;

  const SheetDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.order,
  });
}

const kDefaultSheets = [
  SheetDefinition(id: 'open_water', name: 'Open Water', type: SheetType.openWater, order: 0),
  SheetDefinition(id: 'advance', name: 'Advanced', type: SheetType.advance, order: 1),
  SheetDefinition(id: 'my_select', name: 'My Select', type: SheetType.mySelect, order: 2),
];
