import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eatinpal/core/constants/app_colors.dart';
import 'package:eatinpal/core/constants/app_spacing.dart';
import 'package:eatinpal/core/constants/app_typography.dart';

class OTPInput extends StatefulWidget {
  final void Function(String) onChanged;
  final int length;
  final bool enabled;

  const OTPInput({
    super.key,
    required this.onChanged,
    this.length = 6,
    this.enabled = true,
  });

  @override
  State<OTPInput> createState() => _OTPInputState();
}

class _OTPInputState extends State<OTPInput> {
  static const _CELL_HEIGHT = 56.0;
  static const _CELL_GAP = 10.0;
  static const _FOCUSED_BORDER_WIDTH = 2.0;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    widget.onChanged(_controllers.map((c) => c.text).join());
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: List.generate(widget.length, _cell));
  }

  Widget _cell(int index) {
    final radius = BorderRadius.circular(AppRadius.LG);
    final isLast = index == widget.length - 1;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: isLast ? AppPadding.NONE : _CELL_GAP),
        child: SizedBox(
          height: _CELL_HEIGHT,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            cursorColor: AppColors.PRIMARY,
            style: AppTypography.HEADLINE_MEDIUM.copyWith(
              fontWeight: FontWeight.w700,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => _onChanged(index, value),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.FIELD_FILL,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppPadding.MD,
              ),
              border: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(color: AppColors.BORDER_SOFT),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(color: AppColors.BORDER_SOFT),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(color: AppColors.BORDER_SOFT),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(
                  color: AppColors.PRIMARY,
                  width: _FOCUSED_BORDER_WIDTH,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
