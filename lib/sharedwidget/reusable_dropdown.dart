// reusable_dropdown.dart
// "Reuabel Dropdown" — a simple wrapper class around DropdownFormField
// to provide a unified, easy-to-use reusable dropdown widget.
// Place this file in `lib/widgets/` and import with
// `import 'widgets/reusable_dropdown.dart';`

import 'package:flutter/material.dart';

/// A reusable dropdown widget that wraps [DropdownFormField] for simplicity.
class ReuabelDropdown<T> extends StatelessWidget {
  final List<T>? items;
  final Future<List<T>> Function()? asyncItems;
  final String? hintText;
  final String? labelText;
  final bool enableSearch;
  final bool allowClear;
  final bool enabled;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final FormFieldSetter<T>? onSaved;
  final String Function(T)? itemToString;
  final Widget Function(BuildContext, T)? itemBuilder;
  final T? initialValue;

  const ReuabelDropdown({
    Key? key,
    this.items,
    this.asyncItems,
    this.hintText,
    this.labelText,
    this.enableSearch = false,
    this.allowClear = false,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.itemToString,
    this.itemBuilder,
    this.initialValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownFormField<T>(
      items: items,
      asyncItems: asyncItems,
      hintText: hintText,
      labelText: labelText,
      enableSearch: enableSearch,
      allowClear: allowClear,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
      onSaved: onSaved,
      itemToString: itemToString,
      itemBuilder: itemBuilder,
      initialValue: initialValue,
    );
  }
}

/// Internal DropdownFormField that ReuabelDropdown uses.
class DropdownFormField<T> extends FormField<T> {
  DropdownFormField({
    Key? key,
    T? initialValue,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    FormFieldSetter<T>? onSaved,
    FormFieldValidator<T>? validator,
    ValueChanged<T?>? onChanged,
    this.items,
    this.asyncItems,
    this.itemToString,
    this.itemBuilder,
    this.hintText,
    this.labelText,
    this.allowClear = false,
    this.enableSearch = false,
    this.decoration,
    this.enabled = true,
    this.dropdownHeight = 300,
  })  : _onChanged = onChanged,
        super(
          key: key,
          initialValue: initialValue,
          autovalidateMode: autovalidateMode,
          onSaved: onSaved,
          validator: validator,
          builder: (FormFieldState<T> field) {
            // Cast field.widget to our concrete DropdownFormField<T>
            final dropWidget = field.widget as DropdownFormField<T>;

            final InputDecoration effectiveDecoration =
                (dropWidget.decoration ?? const InputDecoration()).copyWith(
              labelText: dropWidget.labelText,
              hintText: dropWidget.hintText,
              errorText: field.errorText,
              // suffixIcon will be built in the state, so leave null here
            );

            // We rely on the state's methods for suffix icon and display,
            // so simply return a GestureDetector that delegates to state.
            final _DropdownFormFieldState<T> state =
                field as _DropdownFormFieldState<T>;

            return GestureDetector(
              onTap: dropWidget.enabled ? state._handleTap : null,
              child: InputDecorator(
                decoration: effectiveDecoration.copyWith(
                  suffixIcon: state._buildSuffixIcon(field),
                ),
                isEmpty: field.value == null,
                child: state._buildDisplay(field),
              ),
            );
          },
        );

  final List<T>? items;
  final Future<List<T>> Function()? asyncItems;
  final String Function(T)? itemToString;
  final Widget Function(BuildContext context, T item)? itemBuilder;
  final String? hintText;
  final String? labelText;
  final bool allowClear;
  final bool enableSearch;
  final InputDecoration? decoration;
  final bool enabled;
  final double dropdownHeight;
  final ValueChanged<T?>? _onChanged;

  @override
  FormFieldState<T> createState() => _DropdownFormFieldState<T>();
}

class _DropdownFormFieldState<T> extends FormFieldState<T> {
  List<T>? _items;
  bool _loading = false;

  DropdownFormField<T> get _widget => widget as DropdownFormField<T>;

  @override
  void initState() {
    super.initState();
    if (_widget.asyncItems != null) {
      _fetchAsyncItems();
    } else {
      _items = _widget.items ?? [];
    }
  }

  Future<void> _fetchAsyncItems() async {
    setState(() => _loading = true);
    try {
      final results = await _widget.asyncItems!.call();
      setState(() => _items = results);
    } catch (_) {
      setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildDisplay(FormFieldState<T> field) {
    if (_loading) return const Text('Loading...');
    if (field.value == null) return Text(_widget.hintText ?? '');

    final item = field.value as T;
    final display = _widget.itemToString?.call(item) ?? item.toString();
    return Text(display);
  }

  Widget? _buildSuffixIcon(FormFieldState<T> field) {
    if (!_widget.enabled) return null;
    if (_widget.allowClear && field.value != null) {
      return IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          didChange(null);
          _widget._onChanged?.call(null);
        },
      );
    }
    return const Icon(Icons.arrow_drop_down);
  }

  void _handleTap() async {
    if (_widget.asyncItems != null && (_items == null || _items!.isEmpty)) {
      await _fetchAsyncItems();
    }
    final items = _items ?? [];
    final selected = await showModalBottomSheet<T?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SizedBox(
          height: _widget.dropdownHeight,
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: _widget.itemBuilder != null
                    ? _widget.itemBuilder!(context, item)
                    : Text(_widget.itemToString?.call(item) ?? item.toString()),
                onTap: () => Navigator.of(context).pop(item),
              );
            },
          ),
        );
      },
    );

    if (selected != null) {
      didChange(selected);
      _widget._onChanged?.call(selected);
    }
  }
}

/*
EXAMPLE USAGE:

ReuabelDropdown<String>(
  labelText: 'Country',
  hintText: 'Select country',
  items: ['India', 'USA', 'UK'],
  enableSearch: true,
  allowClear: true,
  onChanged: (value) => print('Selected: $value'),
);
*/
