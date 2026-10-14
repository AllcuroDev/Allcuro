import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';

/// Simulated nurse route (Domlur → Indiranagar 12th Main) used until the
/// partner app streams real GPS pings.
const _route = <LatLng>[
  LatLng(12.95820, 77.63480),
  LatLng(12.95960, 77.63640),
  LatLng(12.96130, 77.63720),
  LatLng(12.96290, 77.63790),
  LatLng(12.96420, 77.63960),
  LatLng(12.96580, 77.64010),
  LatLng(12.96760, 77.64050),
  LatLng(12.96910, 77.64130),
  LatLng(12.97030, 77.64290),
  LatLng(12.97180, 77.64330),
];

const _avgSpeedKmh = 18.0;
const _distance = Distance();

/// Precomputed cumulative distances so the marker moves at a steady speed.
final List<double> _cumulative = () {
  final out = <double>[0];
  for (var i = 1; i < _route.length; i++) {
    out.add(out.last + _distance(_route[i - 1], _route[i]));
  }
  return out;
}();

double get _totalMeters => _cumulative.last;

/// Nurse position after travelling [t] (0..1) of the route, plus the index of
/// the segment it is on.
(LatLng, int) _positionAt(double t) {
  final target = _totalMeters * t.clamp(0.0, 1.0);
  for (var i = 1; i < _cumulative.length; i++) {
    if (_cumulative[i] >= target) {
      final segLen = _cumulative[i] - _cumulative[i - 1];
      final f = segLen == 0 ? 0.0 : (target - _cumulative[i - 1]) / segLen;
      final a = _route[i - 1];
      final b = _route[i];
      return (
        LatLng(a.latitude + (b.latitude - a.latitude) * f, a.longitude + (b.longitude - a.longitude) * f),
        i,
      );
    }
  }
  return (_route.last, _route.length - 1);
}

/// Live map of the nurse travelling to the patient's address.
///
/// [progress] drives the nurse along the route (0 = just left, 1 = arrived).
/// The inline variant is compact and opens [NurseLiveMapPage] on tap; the
/// full-screen variant allows free panning and a follow-the-nurse mode.
class NurseLiveMap extends StatefulWidget {
  final Animation<double> progress;
  final String nurseName;
  final bool fullScreen;
  final VoidCallback? onExpand;

  const NurseLiveMap({
    super.key,
    required this.progress,
    required this.nurseName,
    this.fullScreen = false,
    this.onExpand,
  });

  @override
  State<NurseLiveMap> createState() => _NurseLiveMapState();
}

class _NurseLiveMapState extends State<NurseLiveMap> with SingleTickerProviderStateMixin {
  final _map = MapController();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  bool _follow = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_onProgress);
  }

  @override
  void dispose() {
    widget.progress.removeListener(_onProgress);
    _pulse.dispose();
    super.dispose();
  }

  void _onProgress() {
    if (_follow && _mapReady) {
      _map.move(_positionAt(widget.progress.value).$1, _map.camera.zoom);
    }
  }

  void _fitRoute() {
    setState(() => _follow = false);
    _map.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(_route),
      padding: EdgeInsets.fromLTRB(40, widget.fullScreen ? 140 : 70, 40, 40),
    ));
  }

  void _toggleFollow() {
    setState(() => _follow = !_follow);
    if (_follow) _map.move(_positionAt(widget.progress.value).$1, 16.5);
  }

  @override
  Widget build(BuildContext context) {
    final interaction = widget.fullScreen
        ? const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate)
        // Inline map lives inside a ListView: keep vertical drags for scrolling.
        : const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom);

    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(_route),
              padding: EdgeInsets.fromLTRB(40, widget.fullScreen ? 140 : 70, 40, 40),
            ),
            interactionOptions: interaction,
            onMapReady: () => _mapReady = true,
            onPositionChanged: (_, hasGesture) {
              if (hasGesture && _follow) setState(() => _follow = false);
            },
            onTap: widget.fullScreen ? null : (_, _) => widget.onExpand?.call(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              retinaMode: RetinaMode.isHighDensity(context),
              userAgentPackageName: 'com.allcuro.app',
            ),
            AnimatedBuilder(
              animation: widget.progress,
              builder: (_, _) {
                final (pos, seg) = _positionAt(widget.progress.value);
                return PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [..._route.sublist(0, seg), pos],
                      strokeWidth: 4,
                      color: AppColors.mutedForeground.withValues(alpha: 0.5),
                      pattern: StrokePattern.dotted(),
                    ),
                    Polyline(
                      points: [pos, ..._route.sublist(seg)],
                      strokeWidth: 5,
                      color: AppColors.primary,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                );
              },
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _route.last,
                  width: 64,
                  height: 64,
                  child: _HomePin(pulse: _pulse),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: widget.progress,
              builder: (_, _) => MarkerLayer(
                markers: [
                  Marker(
                    point: _positionAt(widget.progress.value).$1,
                    width: 46,
                    height: 46,
                    child: const _NurseMarker(),
                  ),
                ],
              ),
            ),
            const SimpleAttributionWidget(
              source: Text('© OpenStreetMap · CARTO', style: TextStyle(fontSize: 9)),
              backgroundColor: Color(0xB3FFFFFF),
            ),
          ],
        ),
        Positioned(
          left: 12,
          right: 12,
          top: widget.fullScreen ? MediaQuery.paddingOf(context).top + 64 : 12,
          child: AnimatedBuilder(
            animation: widget.progress,
            builder: (_, _) => _EtaChip(progress: widget.progress.value, nurseName: widget.nurseName),
          ),
        ),
        Positioned(
          right: 12,
          bottom: widget.fullScreen ? MediaQuery.paddingOf(context).bottom + 28 : 26,
          child: Column(
            children: [
              if (widget.fullScreen) ...[
                _MapFab(
                  icon: _follow ? Icons.navigation_rounded : Icons.navigation_outlined,
                  active: _follow,
                  tooltip: 'Follow nurse',
                  onTap: _toggleFollow,
                ),
                const SizedBox(height: 8),
              ],
              _MapFab(icon: Icons.center_focus_strong_rounded, tooltip: 'Show full route', onTap: _fitRoute),
              if (!widget.fullScreen) ...[
                const SizedBox(height: 8),
                _MapFab(icon: Icons.open_in_full_rounded, tooltip: 'Expand map', onTap: () => widget.onExpand?.call()),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-screen live tracking map.
class NurseLiveMapPage extends StatelessWidget {
  final Animation<double> progress;
  final String nurseName;

  const NurseLiveMapPage({super.key, required this.progress, required this.nurseName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          NurseLiveMap(progress: progress, nurseName: nurseName, fullScreen: true),
          Positioned(
            left: 12,
            top: MediaQuery.paddingOf(context).top + 8,
            child: _MapFab(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EtaChip extends StatelessWidget {
  final double progress;
  final String nurseName;

  const _EtaChip({required this.progress, required this.nurseName});

  @override
  Widget build(BuildContext context) {
    final arrived = progress >= 1;
    final remainingKm = _totalMeters * (1 - progress) / 1000;
    final mins = (remainingKm / _avgSpeedKmh * 60).ceil().clamp(1, 99);
    final firstName = nurseName.split(' ').first;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: arrived ? AppColors.successSoft : AppColors.secondaryAccentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              arrived ? Icons.check_circle_rounded : Icons.two_wheeler_rounded,
              size: 19,
              color: arrived ? AppColors.success : AppColors.secondaryAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey(arrived),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    arrived ? '$firstName has arrived' : 'Arriving in $mins min',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink),
                  ),
                  Text(
                    arrived
                        ? 'Share your OTP to start the visit'
                        : '$firstName is on the way · ${remainingKm.toStringAsFixed(1)} km away',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.mutedForeground),
                  ),
                ],
              ),
            ),
          ),
          if (!arrived)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.destructive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 7, color: AppColors.destructive),
                  SizedBox(width: 4),
                  Text('LIVE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.destructive)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NurseMarker extends StatelessWidget {
  const _NurseMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: AppColors.secondaryAccent.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 22),
    );
  }
}

class _HomePin extends StatelessWidget {
  final Animation<double> pulse;

  const _HomePin({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: pulse,
          builder: (_, _) => Container(
            width: 24 + 40 * pulse.value,
            height: 24 + 40 * pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.28 * (1 - pulse.value)),
            ),
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 15),
        ),
      ],
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  const _MapFab({required this.icon, required this.tooltip, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? AppColors.primary : AppColors.card,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: active ? Colors.white : AppColors.ink),
          ),
        ),
      ),
    );
  }
}
