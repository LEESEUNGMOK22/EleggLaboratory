class OfflineSummary {
  const OfflineSummary({
    required this.elapsedSec,
    required this.essenceGained,
    required this.residueGained,
    required this.ticketsGained,
    required this.transformCount,
    this.transformGroups = const {},
  });

  final int elapsedSec;
  final double essenceGained;
  final int residueGained;
  final int ticketsGained;
  final int transformCount;
  final Map<String, int> transformGroups;
}

class TicketChargeResult {
  const TicketChargeResult({
    required this.newTickets,
    required this.gainedTickets,
    required this.remainSec,
  });

  final int newTickets;
  final int gainedTickets;
  final int remainSec;
}

TicketChargeResult chargeTickets({
  required int currentTickets,
  required int cap,
  required int elapsedSec,
  required int intervalSec,
  required int remainSec,
}) {
  final total = elapsedSec + remainSec;
  final gained = total ~/ intervalSec;
  final nextTickets = (currentTickets + gained) > cap ? cap : (currentTickets + gained);
  return TicketChargeResult(
    newTickets: nextTickets,
    gainedTickets: nextTickets - currentTickets,
    remainSec: total % intervalSec,
  );
}
