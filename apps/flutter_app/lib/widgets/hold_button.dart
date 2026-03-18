import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that requires a sustained press to activate.
///
/// The [builder] receives the current hold progress (0.0-1.0) so callers
/// can render custom visual feedback (progress ring, bar, opacity, etc.).
class HoldButton extends StatefulWidget {
  /// How long the user must hold to activate.
  final Duration holdDuration;

  /// Called when the hold completes successfully.
  final VoidCallback onActivated;

  /// Whether the button accepts input.
  final bool enabled;

  /// Builds the widget given the current hold [progress] (0.0-1.0).
  final Widget Function(BuildContext context, double progress) builder;

  const HoldButton({
    super.key,
    this.holdDuration = const Duration(milliseconds: 1500),
    required this.onActivated,
    required this.builder,
    this.enabled = true,
  });

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        widget.onActivated();
        _controller.reset();
      }
    });
  }

  @override
  void didUpdateWidget(HoldButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.holdDuration != oldWidget.holdDuration) {
      _controller.duration = widget.holdDuration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled ? (_) => _controller.forward() : null,
      onPointerUp: (_) => _cancel(),
      onPointerCancel: (_) => _cancel(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => widget.builder(context, _controller.value),
      ),
    );
  }

  void _cancel() {
    if (_controller.isAnimating) _controller.reset();
  }
}
