import 'dart:async';

import 'package:flutter/material.dart';

import '../models/irrigation_zone.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Rebuilds its child every [interval] so time-based UI ("offline",
/// "5 min ago") stays correct even when no new data arrives.
class LiveClock extends StatefulWidget {
  const LiveClock({
    super.key,
    required this.builder,
    this.interval = const Duration(seconds: 5),
  });

  final Widget Function(BuildContext context, DateTime now) builder;
  final Duration interval;

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}

/// 🟢 Online / 🔴 Offline · last seen X ago
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    super.key,
    required this.zone,
    this.showLastSeen = true,
  });

  final IrrigationZone zone;
  final bool showLastSeen;

  @override
  Widget build(BuildContext context) {
    return LiveClock(
      builder: (context, now) {
        final online = zone.isOnlineAt(now);
        final color = online ? AppTheme.online : AppTheme.offline;
        var text = online ? 'Online' : 'Offline';
        if (!online && showLastSeen) {
          text += zone.lastSeen == null
              ? ' · never connected'
              : ' · last seen ${timeAgo(zone.lastSeen!, now)}';
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
