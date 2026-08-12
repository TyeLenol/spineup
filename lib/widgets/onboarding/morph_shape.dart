import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'morph_math.dart';
import 'wavy_ring_painter.dart';
import 'cluster_overlay_painter.dart';
import 'shield_layers_painter.dart';

/// MorphShape displays the continuous 72-point radial shape morph driven by SpringSimulation.
class MorphShape extends StatefulWidget {
  /// Fractional shape index (0 = blob, 1 = ring, 2 = burst, 3 = cluster, 4 = shield)
  final double index;
  final Color fill;
  final Color accent;
  final double size;
  final bool overshoot;
  final double? ringProgress; // Progress 0..1 for Screen 2 ring fill
  final bool nodes; // Screen 4 community satellite nodes
  final bool layered; // Screen 5 privacy shield layers

  const MorphShape({
    super.key,
    required this.index,
    required this.fill,
    required this.accent,
    this.size = 300.0,
    this.overshoot = true,
    this.ringProgress,
    this.nodes = false,
    this.layered = false,
  });

  @override
  State<MorphShape> createState() => _MorphShapeState();
}

class _MorphShapeState extends State<MorphShape> with TickerProviderStateMixin {
  late AnimationController _morphController;
  late AnimationController _ringController;
  late AnimationController _wavePhaseController;
  late AnimationController _clusterController;
  late AnimationController _shieldController;

  double _currentMorphIndex = 0.0;
  Timer? _ringStartTimer;

  @override
  void initState() {
    super.initState();
    _currentMorphIndex = widget.index;

    // Morph controller
    _morphController = AnimationController.unbounded(vsync: this);
    _morphController.value = widget.index;
    _morphController.addListener(() {
      setState(() {
        _currentMorphIndex = _morphController.value;
      });
    });

    // Ring fill controller
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Wave phase animation (Screen 2 continuous ripple phase)
    _wavePhaseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Cluster nodes controller (Screen 4)
    _clusterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Shield layers controller (Screen 5)
    _shieldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _triggerAnimations();
    }
  }

  @override
  void didUpdateWidget(covariant MorphShape oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index || oldWidget.overshoot != widget.overshoot) {
      _animateMorphTo(widget.index);
    }
    if (oldWidget.ringProgress != widget.ringProgress || oldWidget.nodes != widget.nodes || oldWidget.layered != widget.layered) {
      _triggerAnimations();
    }
  }

  void _animateMorphTo(double targetIndex) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      _morphController.value = targetIndex;
      return;
    }

    final stiffness = widget.overshoot ? 140.0 : 120.0;
    final damping = widget.overshoot ? 12.0 : 26.0;

    final simulation = SpringSimulation(
      SpringDescription(mass: 1.0, stiffness: stiffness, damping: damping),
      _morphController.value,
      targetIndex,
      0.0,
    );

    _morphController.animateWith(simulation);
  }

  void _triggerAnimations() {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    // Ring fill
    _ringStartTimer?.cancel();
    if (widget.ringProgress != null) {
      if (disableAnimations) {
        _ringController.value = widget.ringProgress!;
      } else {
        _wavePhaseController.repeat();
        _ringStartTimer = Timer(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          final simulation = SpringSimulation(
            SpringDescription(
              mass: 1.0,
              stiffness: widget.overshoot ? 90.0 : 120.0,
              damping: widget.overshoot ? 7.5 : 24.0,
            ),
            _ringController.value,
            widget.ringProgress!,
            0.0,
          );
          _ringController.animateWith(simulation);
        });
      }
    } else {
      _wavePhaseController.stop();
    }

    // Nodes (Screen 4)
    if (widget.nodes) {
      if (disableAnimations) {
        _clusterController.value = 1.0;
      } else {
        _clusterController.forward(from: 0.0);
      }
    } else {
      _clusterController.value = 0.0;
    }

    // Shield (Screen 5)
    if (widget.layered) {
      if (disableAnimations) {
        _shieldController.value = 1.0;
      } else {
        _shieldController.forward(from: 0.0);
      }
    } else {
      _shieldController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _ringStartTimer?.cancel();
    _morphController.dispose();
    _ringController.dispose();
    _wavePhaseController.dispose();
    _clusterController.dispose();
    _shieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _morphController,
          _ringController,
          _wavePhaseController,
          _clusterController,
          _shieldController,
        ]),
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _MorphShapeMasterPainter(
              morphIndex: _currentMorphIndex,
              fill: widget.fill,
              accent: widget.accent,
              ringProgress: widget.ringProgress != null ? _ringController.value : null,
              wavePhase: _wavePhaseController.value * kTau * 2,
              nodes: widget.nodes,
              clusterProgress: _clusterController.value,
              layered: widget.layered,
              shieldProgress: _shieldController.value,
              disableAnimations: disableAnimations,
            ),
          );
        },
      ),
    );
  }
}

class _MorphShapeMasterPainter extends CustomPainter {
  final double morphIndex;
  final Color fill;
  final Color accent;
  final double? ringProgress;
  final double wavePhase;
  final bool nodes;
  final double clusterProgress;
  final bool layered;
  final double shieldProgress;
  final bool disableAnimations;

  _MorphShapeMasterPainter({
    required this.morphIndex,
    required this.fill,
    required this.accent,
    required this.ringProgress,
    required this.wavePhase,
    required this.nodes,
    required this.clusterProgress,
    required this.layered,
    required this.shieldProgress,
    required this.disableAnimations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.39; // Matches 78 on 200px viewBox

    // 1. Draw base morphed shape
    final shapePath = buildMorphedPath(
      morphIndex,
      center: Offset(cx, cy),
      radius: radius,
    );

    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;

    canvas.drawPath(shapePath, fillPaint);

    // 2. Draw Screen 2 Wavy Ring Fill
    if (ringProgress != null) {
      final wavyPainter = WavyRingPainter(
        progress: ringProgress!,
        color: accent,
        phase: wavePhase,
      );
      wavyPainter.paint(canvas, size);
    }

    // 3. Draw Screen 4 Community Cluster Overlay
    if (nodes && clusterProgress > 0.0) {
      final clusterPainter = ClusterOverlayPainter(
        color: accent,
        linkProgress: clusterProgress.clamp(0.0, 1.0),
        nodeScale: clusterProgress.clamp(0.0, 1.0),
        opacity: clusterProgress.clamp(0.0, 1.0),
      );
      clusterPainter.paint(canvas, size);
    }

    // 4. Draw Screen 5 Privacy Shield Overlay
    if (layered && shieldProgress > 0.0) {
      final shieldPainter = ShieldLayersPainter(
        color: accent,
        scale: 1.25 - 0.25 * shieldProgress, // Scale 1.25 -> 1.0
        lineProgress: shieldProgress,
        opacity: shieldProgress,
      );
      shieldPainter.paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant _MorphShapeMasterPainter oldDelegate) {
    return oldDelegate.morphIndex != morphIndex ||
        oldDelegate.fill != fill ||
        oldDelegate.accent != accent ||
        oldDelegate.ringProgress != ringProgress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.nodes != nodes ||
        oldDelegate.clusterProgress != clusterProgress ||
        oldDelegate.layered != layered ||
        oldDelegate.shieldProgress != shieldProgress;
  }
}
