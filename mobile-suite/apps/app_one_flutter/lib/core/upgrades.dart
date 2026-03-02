enum UpgradeCategory { summon, production, transform, clicker }

class UpgradeDef {
  const UpgradeDef({
    required this.id,
    required this.name,
    required this.category,
    required this.cost,
    this.maxLevel = 1,
  });

  final String id;
  final String name;
  final UpgradeCategory category;
  final double cost;
  final int maxLevel;
}

const List<UpgradeDef> kUpgradeDefs = [
  UpgradeDef(id: 'summon_charge_1', name: '티켓 충전 -10%', category: UpgradeCategory.summon, cost: 100),
  UpgradeDef(id: 'summon_cap_1', name: '티켓 cap +10', category: UpgradeCategory.summon, cost: 120),
  UpgradeDef(id: 'summon_bias_fire', name: '불 확률 +5%', category: UpgradeCategory.summon, cost: 140),
  UpgradeDef(id: 'prod_all_1', name: '전체 생산 +10%', category: UpgradeCategory.production, cost: 150),
  UpgradeDef(id: 'prod_offline_1', name: '오프라인 배율 +10%', category: UpgradeCategory.production, cost: 160),
  UpgradeDef(id: 'prod_recycle_1', name: '분해 보상 +20%', category: UpgradeCategory.production, cost: 110),
  UpgradeDef(id: 'trans_residue_1', name: '변성 잔재 +15%', category: UpgradeCategory.transform, cost: 170),
  UpgradeDef(id: 'trans_speed_1', name: '변성 시간 -10%', category: UpgradeCategory.transform, cost: 180),
  UpgradeDef(id: 'click_tap_1', name: '탭 +1', category: UpgradeCategory.clicker, cost: 70),
  UpgradeDef(id: 'click_tap_2', name: '탭 +2', category: UpgradeCategory.clicker, cost: 140),
];
