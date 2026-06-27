// ---- Generator / Unit ----
class GeneratorUnit {
  final String name;
  final String status;
  double mw;
  final double hz;
  final int temp;
  final String voltage;

  GeneratorUnit({
    required this.name,
    required this.status,
    required this.mw,
    required this.hz,
    required this.temp,
    required this.voltage,
  });
}

class GeneratorStation {
  final String station;
  final List<GeneratorUnit> units;
  GeneratorStation({required this.station, required this.units});
}

// ---- Transmission ----
class TransmissionLine {
  final String id;
  final String from;
  final String to;
  final int kv;
  final int load;
  final int mva;
  final bool ok;
  TransmissionLine({
    required this.id,
    required this.from,
    required this.to,
    required this.kv,
    required this.load,
    required this.mva,
    required this.ok,
  });
}

// ---- Alert ----
class AlertItem {
  final String type;
  final String payload;
  final String zone;
  final String level;
  AlertItem({
    required this.type,
    required this.payload,
    required this.zone,
    required this.level,
  });
}

// ---- Sample data (ປັບປຸງໃໝ່ຕາມຄວາມຕ້ອງການ) ----
List<GeneratorStation> sampleGenerators() => [
  GeneratorStation(station: 'Station A', units: [
    GeneratorUnit(name: 'Unit 01', status: 'online', mw: 2.75, hz: 50.00, temp: 55, voltage: '22 kV'),
    GeneratorUnit(name: 'Unit 02', status: 'online', mw: 2.75, hz: 50.00, temp: 55, voltage: '22 kV'),
  ]),
];

List<TransmissionLine> sampleTransmission() => [
  TransmissionLine(id: 'TL-01', from: 'Station A', to: 'Subsystem', kv: 22, load: 5, mva: 10, ok: true),
];

List<AlertItem> sampleAlerts() => [
  AlertItem(type: 'INFO', payload: 'Unit 01 & 02 ຜະລິດລວມ 5.5 MW', zone: 'Station A', level: 'info'),
  AlertItem(type: 'OK', payload: 'ລະບົບກຳລັງເຮັດວຽກປົກກະຕິ', zone: 'System', level: 'info'),
];