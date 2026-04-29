import 'package:flutter/material.dart';
import '../config/theme.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final int minLines;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.readOnly = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      obscureText: _obscure,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: widget.obscureText
            ? InkWell(
                onTap: () {
                  setState(() {
                    _obscure = !_obscure;
                  });
                },
                child: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                ),
              )
            : widget.suffixIcon != null
                ? InkWell(
                    onTap: widget.onSuffixIconPressed,
                    child: Icon(widget.suffixIcon),
                  )
                : null,
      ),
    );
  }
}
