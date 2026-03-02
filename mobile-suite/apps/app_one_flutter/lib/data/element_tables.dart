enum ElementForm {
  flame,
  smoke,
  ash,
  soot,
  water,
  vapor,
  cloud,
  dew,
  soil,
  mud,
  clay,
  stone,
  air,
  breeze,
  gust,
  storm,
}

class TransformRule {
  const TransformRule({
    required this.from,
    required this.to,
    required this.baseDurationSec,
    required this.baseResidue,
  });

  final ElementForm from;
  final ElementForm to;
  final int baseDurationSec;
  final int baseResidue;
}

const List<TransformRule> kTransformRules = [
  TransformRule(from: ElementForm.flame, to: ElementForm.smoke, baseDurationSec: 60, baseResidue: 1),
  TransformRule(from: ElementForm.smoke, to: ElementForm.ash, baseDurationSec: 90, baseResidue: 2),
  TransformRule(from: ElementForm.ash, to: ElementForm.soot, baseDurationSec: 120, baseResidue: 3),

  TransformRule(from: ElementForm.water, to: ElementForm.vapor, baseDurationSec: 60, baseResidue: 1),
  TransformRule(from: ElementForm.vapor, to: ElementForm.cloud, baseDurationSec: 90, baseResidue: 2),
  TransformRule(from: ElementForm.cloud, to: ElementForm.dew, baseDurationSec: 120, baseResidue: 3),

  TransformRule(from: ElementForm.soil, to: ElementForm.mud, baseDurationSec: 60, baseResidue: 1),
  TransformRule(from: ElementForm.mud, to: ElementForm.clay, baseDurationSec: 90, baseResidue: 2),
  TransformRule(from: ElementForm.clay, to: ElementForm.stone, baseDurationSec: 120, baseResidue: 3),

  TransformRule(from: ElementForm.air, to: ElementForm.breeze, baseDurationSec: 60, baseResidue: 1),
  TransformRule(from: ElementForm.breeze, to: ElementForm.gust, baseDurationSec: 90, baseResidue: 2),
  TransformRule(from: ElementForm.gust, to: ElementForm.storm, baseDurationSec: 120, baseResidue: 3),
];

TransformRule? ruleFor(ElementForm form) {
  for (final rule in kTransformRules) {
    if (rule.from == form) return rule;
  }
  return null;
}
