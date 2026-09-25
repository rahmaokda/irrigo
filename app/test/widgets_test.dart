import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irrigo/models/irrigation_zone.dart';
import 'package:irrigo/theme/app_theme.dart';
import 'package:irrigo/widgets/device_card.dart';
import 'package:irrigo/widgets/pump_card.dart';

IrrigationZone zone({bool auto = true, bool cmd = false, bool state = false}) =>
    IrrigationZone.fromMap('esp32_01', 'zone1', {
      'name': 'Backyard',
      'moisture': 28,
      'threshold': 30,
      'autoMode': auto,
      'pumpCommand': cmd,
      'pumpState': state,
      'online': true,
      'lastSeen': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

Widget wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('dashboard card shows live values', (tester) async {
    await tester.pumpWidget(
      wrap(DeviceCard(zone: zone(state: true), onTap: () {})),
    );
    expect(find.text('Backyard'), findsOneWidget);
    expect(find.text('28% ⚠️'), findsOneWidget);
    expect(find.text('ON'), findsOneWidget);
    expect(find.text('AUTO'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('manual mode: start button sends command, shows pending', (
    tester,
  ) async {
    bool? sent;
    await tester.pumpWidget(
      wrap(
        PumpCard(
          zone: zone(auto: false, cmd: true, state: false),
          online: true,
          onModeChanged: (_) {},
          onPumpChanged: (v) => sent = v,
        ),
      ),
    );
    expect(find.text('Starting…'), findsOneWidget);
    await tester.tap(find.text('Stop pump'));
    expect(sent, isFalse);
  });

  testWidgets('manual start is disabled while offline', (tester) async {
    await tester.pumpWidget(
      wrap(
        PumpCard(
          zone: zone(auto: false),
          online: false,
          onModeChanged: (_) {},
          onPumpChanged: (_) => fail('should not send'),
        ),
      ),
    );
    await tester.tap(find.text('Start pump'));
    expect(find.textContaining('offline'), findsOneWidget);
  });
}
