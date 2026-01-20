import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/extensions/extensions.dart';

class CustomOtpField extends StatefulWidget {
  final Function(String?)? onCodeChanged;
  final Function(String)? onCodeSubmitted;
  final String? currentCode;

  const CustomOtpField({
    Key? key,
    this.onCodeChanged,
    this.onCodeSubmitted,
    this.currentCode,
  }) : super(key: key);

  @override
  State<CustomOtpField> createState() => _CustomOtpFieldState();
}

class _CustomOtpFieldState extends State<CustomOtpField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (index) => TextEditingController());
    _focusNodes = List.generate(6, (index) => FocusNode());
    _initializeCode();
  }

  void _initializeCode() {
    if (widget.currentCode != null && widget.currentCode!.isNotEmpty) {
      for (int i = 0; i < 6; i++) {
        if (i < widget.currentCode!.length) {
          _controllers[i].text = widget.currentCode![i];
        }
      }
    }
  }

  @override
  void didUpdateWidget(CustomOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentCode != oldWidget.currentCode &&
        widget.currentCode != _getOtp()) {
      _updateControllersFromCode();
    }
  }

  void _updateControllersFromCode() {
    String code = widget.currentCode ?? "";
    for (int i = 0; i < 6; i++) {
      if (i < code.length) {
        _controllers[i].text = code[i];
      } else {
        _controllers[i].clear();
      }
    }
  }

  String _getOtp() {
    return _controllers.map((c) => c.text).join();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        _focusNodes[index].unfocus();
        widget.onCodeSubmitted?.call(_getOtp());
      }
    }
    widget.onCodeChanged?.call(_getOtp());
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 40,
          child: RawKeyboardListener(
            focusNode: FocusNode(), // Required for listening
            onKey: (event) {
              if (event is RawKeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.backspace) {
                  if (_controllers[index].text.isEmpty && index > 0) {
                    FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                    // optional: clear previous field
                    // _controllers[index - 1].clear();
                    // widget.onCodeChanged?.call(_getOtp());
                  }
                }
              }
            },
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                LengthLimitingTextInputFormatter(1),
                FilteringTextInputFormatter.digitsOnly,
              ],
              style:
                  TextStyle(fontSize: 20, color: context.color.textColorDark),
              decoration: InputDecoration(
                counterText: "",
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: context.color.textColorDark.withOpacity(0.5)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.color.territoryColor),
                ),
              ),
              onChanged: (val) => _onChanged(val, index),
            ),
          ),
        );
      }),
    );
  }
}
