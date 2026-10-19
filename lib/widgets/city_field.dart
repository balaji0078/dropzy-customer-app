import 'package:flutter/material.dart';

import '../core/cities.dart';
import '../core/theme.dart';

/// A searchable city picker backed by [southIndiaCities]. Type to filter,
/// tap to select. Syncs directly with the provided [controller].
class CityField extends StatefulWidget {
  const CityField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.bordered = true,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;

  /// `true` for a full bordered form field (Booking); `false` for the borderless
  /// variant used inside the Home card (icon supplied by the parent Row).
  final bool bordered;

  @override
  State<CityField> createState() => _CityFieldState();
}

class _CityFieldState extends State<CityField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focus,
      displayStringForOption: (o) => o,
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        final matches = q.isEmpty
            ? southIndiaCities
            : southIndiaCities.where((c) => c.toLowerCase().contains(q));
        return matches.take(80);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => onSubmit(),
          decoration: widget.bordered
              ? InputDecoration(
                  labelText: widget.hint,
                  prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                )
              : InputDecoration(
                  hintText: widget.hint,
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final width = MediaQuery.of(context).size.width - (widget.bordered ? 40 : 72);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: DropzyColors.surfaceAlt,
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 280, maxWidth: width),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final city = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(city),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      child: Row(
                        children: [
                          const Icon(Icons.location_city_rounded,
                              size: 18, color: DropzyColors.inkSoft),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(city,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
