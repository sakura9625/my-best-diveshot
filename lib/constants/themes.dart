enum TileCategory { creature, scene }

class ThemeDefinition {
  final String id;
  final String name;
  final TileCategory category;
  final int gridIndex;

  const ThemeDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.gridIndex,
  });
}

const List<ThemeDefinition> kThemes = [
  ThemeDefinition(id: 'clownfish',      name: 'クマノミ',             category: TileCategory.creature, gridIndex: 0),
  ThemeDefinition(id: 'blue_water',     name: '青抜き',               category: TileCategory.scene,    gridIndex: 1),
  ThemeDefinition(id: 'sea_turtle',     name: 'ウミガメ',             category: TileCategory.creature, gridIndex: 2),
  ThemeDefinition(id: 'squid_octopus',  name: 'イカ・タコ',           category: TileCategory.creature, gridIndex: 3),
  ThemeDefinition(id: 'symbiosis',      name: '共生',                 category: TileCategory.scene,    gridIndex: 4),
  ThemeDefinition(id: 'nudibranch',     name: 'ウミウシ',             category: TileCategory.creature, gridIndex: 5),
  ThemeDefinition(id: 'silhouette',     name: 'シルエット',           category: TileCategory.scene,    gridIndex: 6),
  ThemeDefinition(id: 'shrimp_crab',    name: 'エビ・カニ',           category: TileCategory.creature, gridIndex: 7),
  ThemeDefinition(id: 'garden_eel',     name: 'チンアナゴ',           category: TileCategory.creature, gridIndex: 8),
  ThemeDefinition(id: 'juvenile',       name: '幼魚',                 category: TileCategory.creature, gridIndex: 9),
  ThemeDefinition(id: 'hawkfish',       name: 'ゴンベ系',             category: TileCategory.creature, gridIndex: 10),
  ThemeDefinition(id: 'camouflage',     name: '擬態',                 category: TileCategory.scene,    gridIndex: 11),
  ThemeDefinition(id: 'free',           name: '自由枠',               category: TileCategory.creature, gridIndex: 12),
  ThemeDefinition(id: 'frogfish',       name: 'カエルアンコウ系',     category: TileCategory.creature, gridIndex: 13),
  ThemeDefinition(id: 'seahorse',       name: 'タツノオトシゴ系',     category: TileCategory.creature, gridIndex: 14),
  ThemeDefinition(id: 'goby',           name: 'ハゼ',                 category: TileCategory.creature, gridIndex: 15),
  ThemeDefinition(id: 'terrain_light',  name: '地形・光',             category: TileCategory.scene,    gridIndex: 16),
  ThemeDefinition(id: 'coral',          name: '珊瑚礁',               category: TileCategory.scene,    gridIndex: 17),
  ThemeDefinition(id: 'cute',           name: 'かわいい枠',           category: TileCategory.creature, gridIndex: 18),
  ThemeDefinition(id: 'anthias',        name: 'ハナダイ系',           category: TileCategory.creature, gridIndex: 19),
  ThemeDefinition(id: 'jawfish_blenny', name: 'ジョーフィッシュ・ギンポ系', category: TileCategory.creature, gridIndex: 20),
  ThemeDefinition(id: 'school',         name: '群れ（魚群）',         category: TileCategory.scene,    gridIndex: 21),
  ThemeDefinition(id: 'pelagic',        name: '大物回遊魚',           category: TileCategory.creature, gridIndex: 22),
  ThemeDefinition(id: 'shark_ray',      name: 'サメ・エイ',           category: TileCategory.creature, gridIndex: 23),
  ThemeDefinition(id: 'manta',          name: 'マンタ',               category: TileCategory.creature, gridIndex: 24),
];

const List<List<int>> kBingoLines = [
  [0, 1, 2, 3, 4],
  [5, 6, 7, 8, 9],
  [10, 11, 12, 13, 14],
  [15, 16, 17, 18, 19],
  [20, 21, 22, 23, 24],
  [0, 5, 10, 15, 20],
  [1, 6, 11, 16, 21],
  [2, 7, 12, 17, 22],
  [3, 8, 13, 18, 23],
  [4, 9, 14, 19, 24],
  [0, 6, 12, 18, 24],
  [4, 8, 12, 16, 20],
];
