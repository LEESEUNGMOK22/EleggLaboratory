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
  // Summon (5)
  UpgradeDef(id: 'summon_charge_1', name: '티켓 충전 -10%', category: UpgradeCategory.summon, cost: 100),
  UpgradeDef(id: 'summon_cap_1', name: '티켓 cap +10', category: UpgradeCategory.summon, cost: 120),
  UpgradeDef(id: 'summon_batch_10', name: '연속 소환 안정화', category: UpgradeCategory.summon, cost: 130),
  UpgradeDef(id: 'summon_bias_fire', name: '불 확률 +5%', category: UpgradeCategory.summon, cost: 140),
  UpgradeDef(id: 'summon_bias_pick', name: '속성 편향 슬롯 +1', category: UpgradeCategory.summon, cost: 150),

  // Production (5)
  UpgradeDef(id: 'prod_all_1', name: '전체 생산 +10%', category: UpgradeCategory.production, cost: 150),
  UpgradeDef(id: 'prod_offline_1', name: '오프라인 배율 +10%', category: UpgradeCategory.production, cost: 160),
  UpgradeDef(id: 'prod_element_1', name: '특정 계열 생산 +15%', category: UpgradeCategory.production, cost: 170),
  UpgradeDef(id: 'prod_board_expand_1', name: '보드 확장 +6칸(준비)', category: UpgradeCategory.production, cost: 180),
  UpgradeDef(id: 'prod_recycle_1', name: '분해 보상 +20%', category: UpgradeCategory.production, cost: 110),

  // Transform (5)
  UpgradeDef(id: 'trans_residue_1', name: '변성 잔재 +15%', category: UpgradeCategory.transform, cost: 170),
  UpgradeDef(id: 'trans_speed_1', name: '변성 시간 -10%', category: UpgradeCategory.transform, cost: 180),
  UpgradeDef(id: 'trans_stabilizer', name: '안정화(준비)', category: UpgradeCategory.transform, cost: 190),
  UpgradeDef(id: 'trans_catalyst', name: '촉진(준비)', category: UpgradeCategory.transform, cost: 200),
  UpgradeDef(id: 'trans_penalty_reduce', name: '변성 생산 페널티 완화', category: UpgradeCategory.transform, cost: 210),

  // Clicker (5)
  UpgradeDef(id: 'click_tap_1', name: '탭 +1', category: UpgradeCategory.clicker, cost: 70),
  UpgradeDef(id: 'click_tap_2', name: '탭 +2', category: UpgradeCategory.clicker, cost: 140),
  UpgradeDef(id: 'click_burst_1', name: '탭 버스트(준비)', category: UpgradeCategory.clicker, cost: 160),
  UpgradeDef(id: 'click_auto_1', name: '자동 탭(준비)', category: UpgradeCategory.clicker, cost: 180),
  UpgradeDef(id: 'click_ticket_gauge', name: '탭→티켓 게이지(준비)', category: UpgradeCategory.clicker, cost: 200),
];
