import 'package:flutter/material.dart';

class InputWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onDescriptionChanged;
  final String labelText;
  final String hintText;
  final TextInputType? keyboardType;
  final List<String> suggestions;
  final Function(String)? onSuggestionSelected;

  const InputWidget({
    super.key,
    required this.controller,
    required this.onDescriptionChanged,
    required this.labelText,
    required this.hintText,
    this.keyboardType,
    this.suggestions = const [],
    this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty || onSuggestionSelected == null) {
      return _buildRegularInput(context);
    }

    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return suggestions;
      },
      onSelected: (String selection) {
        onSuggestionSelected!(selection);
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        fieldController.text = controller.text;
        fieldController.selection = controller.selection;

        return _buildTextField(
          context,
          fieldController,
          fieldFocusNode,
          (value) {
            controller.text = value;
            controller.selection = fieldController.selection;
            onDescriptionChanged(value);
          },
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        void Function(String) onSelected,
        Iterable<String> options,
      ) {
        return _buildOptionsView(context, onSelected, options);
      },
    );
  }

  Widget _buildRegularInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.4),
      ),
      child: TextField(
        controller: controller,
        onChanged: onDescriptionChanged,
        keyboardType: keyboardType ?? TextInputType.text,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController fieldController,
    FocusNode focusNode,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.4),
      ),
      child: TextField(
        controller: fieldController,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: keyboardType ?? TextInputType.text,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildOptionsView(
    BuildContext context,
    void Function(String) onSelected,
    Iterable<String> options,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 200),
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (BuildContext context, int index) {
              final option = options.elementAt(index);
              return InkWell(
                onTap: () => onSelected(option),
                child: Container(
                  decoration: BoxDecoration(
                    border: index != options.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          )
                        : null,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    option,
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
