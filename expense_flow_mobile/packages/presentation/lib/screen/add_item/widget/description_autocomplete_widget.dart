import 'package:flutter/material.dart';

class DescriptionAutocompleteWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onTextChanged;
  final String labelText;
  final String hintText;
  final TextInputType? keyboardType;
  final List<String> suggestions;
  final Function(String)? onSuggestionSelected;
  final bool isLoadingSuggestions;

  const DescriptionAutocompleteWidget({
    super.key,
    required this.controller,
    required this.onTextChanged,
    required this.labelText,
    required this.hintText,
    this.keyboardType,
    this.suggestions = const [],
    this.onSuggestionSelected,
    this.isLoadingSuggestions = false,
  });

  @override
  State<DescriptionAutocompleteWidget> createState() =>
      _CustomAutocompleteInputState();
}

class _CustomAutocompleteInputState
    extends State<DescriptionAutocompleteWidget> {
  final layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  bool _isFocused = false;
  List<String> _currentSuggestions = [];
  bool _ignoreNextTextChange = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _currentSuggestions = widget.suggestions;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isFocused && _currentSuggestions.isNotEmpty) {
        _showOverlay();
      }
    });
  }

  @override
  void didUpdateWidget(DescriptionAutocompleteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.suggestions != oldWidget.suggestions) {
      _currentSuggestions = widget.suggestions;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isFocused) {
          _updateOverlay();
        }
      });
    }
  }

  void _onFocusChange() {
    final hasFocus = _focusNode.hasFocus;

    if (hasFocus != _isFocused) {
      _isFocused = hasFocus;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isFocused) {
          if (_currentSuggestions.isNotEmpty) {
            _showOverlay();
          }
        } else {
          _removeOverlay();
        }
      });
    }
  }

  void _updateOverlay() {
    _removeOverlay();
    if (_currentSuggestions.isNotEmpty) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    _overlayEntry = _createOverlayEntry();
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 4.0,
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: widget.isLoadingSuggestions
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _currentSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _currentSuggestions[index];
                        return InkWell(
                          onTap: () {
                            _selectSuggestion(suggestion);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: index != _currentSuggestions.length - 1
                                  ? Border(
                                      bottom: BorderSide(
                                        color:
                                            Colors.white.withValues(alpha: 0.1),
                                      ),
                                    )
                                  : null,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectSuggestion(String suggestion) {
    _ignoreNextTextChange = true;

    widget.controller.text = suggestion;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );

    if (widget.onSuggestionSelected != null) {
      widget.onSuggestionSelected!(suggestion);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeOverlay();
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.4),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: (value) {
            if (_ignoreNextTextChange) {
              _ignoreNextTextChange = false;
              return;
            }

            widget.onTextChanged(value);

            if (value.isEmpty && _overlayEntry != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _removeOverlay();
              });
            }
          },
          keyboardType: widget.keyboardType ?? TextInputType.text,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: InputBorder.none,
            suffixIcon: widget.isLoadingSuggestions
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
