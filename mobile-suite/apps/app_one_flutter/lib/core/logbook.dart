enum LogType { summon, merge, transform, offlineSummary, upgrade }

class LogEvent {
  const LogEvent({
    required this.timestampMs,
    required this.type,
    this.deltaEssence = 0,
    this.deltaResidue = 0,
    this.deltaTickets = 0,
    this.payload = const {},
    this.isOffline = false,
  });

  final int timestampMs;
  final LogType type;
  final double deltaEssence;
  final int deltaResidue;
  final int deltaTickets;
  final Map<String, Object> payload;
  final bool isOffline;
}
