import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../courses/domain/golf_hole.dart';

/// Foreground-only distances to catalogued coordinates. Location stays on device.
class GreenDistanceCard extends StatefulWidget {
  const GreenDistanceCard({required this.hole, super.key});
  final GolfHole hole;

  @override
  State<GreenDistanceCard> createState() => _GreenDistanceCardState();
}

class _GreenDistanceCardState extends State<GreenDistanceCard>
    with WidgetsBindingObserver {
  StreamSubscription<Position>? _updates;
  Position? _position;
  String? _message;
  bool _loading = false;
  bool _foreground = true;
  Animation<double>? _routeTransition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final transition = ModalRoute.of(context)?.secondaryAnimation;
    if (transition == _routeTransition) return;
    _routeTransition?.removeStatusListener(_onRouteTransition);
    _routeTransition = transition;
    _routeTransition?.addStatusListener(_onRouteTransition);
  }

  void _onRouteTransition(AnimationStatus status) {
    if (status == AnimationStatus.forward || status == AnimationStatus.completed) {
      _stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _stop();
  }

  Future<void> _stop() async {
    final updates = _updates;
    _updates = null;
    await updates?.cancel();
    if (mounted) setState(() => _position = null);
  }

  Future<void> _start() async {
    if (_loading || _updates != null) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Turn on location services to see distances.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(
          'Location permission is needed to show your distances.',
        );
      }
      if (!mounted || !_foreground || (ModalRoute.of(context)?.isCurrent != true)) return;
      _updates =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen(
            (position) {
              if (mounted) setState(() => _position = position);
            },
            onError: (_) {
              if (mounted)
                setState(() => _message = 'Location unavailable. Try again.');
              _stop();
            },
          );
      setState(() {});
    } catch (error) {
      if (mounted)
        setState(
          () => _message = error is StateError
              ? error.message
              : 'Location unavailable. Try again.',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeTransition?.removeStatusListener(_onRouteTransition);
    _updates?.cancel();
    super.dispose();
  }

  String _distance(double latitude, double longitude) {
    final position = _position;
    if (position == null ||
        latitude == 0 ||
        longitude == 0 ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180)
      return '—';
    return '${Geolocator.distanceBetween(position.latitude, position.longitude, latitude, longitude).round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final hole = widget.hole;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distance to green',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Front ${_distance(hole.greenFrontLatitude, hole.greenFrontLongitude)}   ·   Middle ${_distance(hole.greenCentreLatitude, hole.greenCentreLongitude)}   ·   Back ${_distance(hole.greenBackLatitude, hole.greenBackLongitude)}',
            ),
            const SizedBox(height: 8),
            Text(
              _position == null
                  ? 'Uses your phone’s location while this screen is open.'
                  : 'GPS accuracy approximately ${_position!.accuracy.round()} m. Course coordinates may be unverified.',
            ),
            if (_message != null) Text(_message!),
            TextButton.icon(
              onPressed: _loading
                  ? null
                  : _updates == null
                  ? _start
                  : _stop,
              icon: Icon(
                _updates == null ? Icons.my_location : Icons.location_disabled,
              ),
              label: Text(
                _loading
                    ? 'Checking location…'
                    : _updates == null
                    ? 'Use my location'
                    : 'Stop location',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
