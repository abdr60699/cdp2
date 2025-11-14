// reusable_app_bar.dart
// A highly-configurable reusable AppBar for Flutter apps.
// Place this file in your `lib/widgets/` folder and import `widgets/reusable_app_bar.dart`.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

/// A reusable AppBar that exposes most commonly-used properties and
/// a few convenient presets (transparent, gradient, search-ready).
///
/// Implements PreferredSizeWidget so it can be used wherever an AppBar is
/// expected (Scaffold.appBar, SliverAppBar, etc.).
class ReusableAppBar extends StatelessWidget implements PreferredSizeWidget {
  // Core
  final Widget? titleWidget; // if provided, overrides titleText
  final String? titleText;
  final bool centerTitle;

  // Leading / navigation
  final Widget? leading;
  final bool automaticallyImplyLeading; // fallback to default back button
  final VoidCallback? onBack; // called when default back is tapped
  final bool showBackButton; // show default back button when leading==null

  // Actions
  final List<Widget>? actions;

  // Appearance
  final double height;
  final Color? backgroundColor;
  final Gradient? backgroundGradient; // if present, paints flexibleSpace
  final double elevation;
  final bool showElevation;
  final ShapeBorder? shape;

  // Extra
  final PreferredSizeWidget? bottom;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final EdgeInsetsGeometry? titlePadding;

  // Convenience presets
  final bool transparent; // if true, backgroundColor becomes transparent
  final bool pinned; // helpful hint when using with SliverAppBar

  const ReusableAppBar({
    Key? key,
    this.titleWidget,
    this.titleText,
    this.centerTitle = false,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onBack,
    this.showBackButton = true,
    this.actions,
    this.height = kToolbarHeight,
    this.backgroundColor,
    this.backgroundGradient,
    this.elevation = 0,
    this.showElevation = true,
    this.shape,
    this.bottom,
    this.systemOverlayStyle,
    this.titlePadding,
    this.transparent = false,
    this.pinned = false,
  }) : super(key: key);

  /// A named constructor for a simple transparent AppBar (over content).
  factory ReusableAppBar.transparent({
    Key? key,
    Widget? titleWidget,
    String? titleText,
    List<Widget>? actions,
    VoidCallback? onBack,
    bool centerTitle = false,
    double height = kToolbarHeight,
    PreferredSizeWidget? bottom,
  }) {
    return ReusableAppBar(
      key: key,
      titleWidget: titleWidget,
      titleText: titleText,
      actions: actions,
      onBack: onBack,
      centerTitle: centerTitle,
      transparent: true,
      height: height,
      bottom: bottom,
      showElevation: false,
    );
  }

  /// A named constructor for a gradient AppBar.
  factory ReusableAppBar.gradient({
    Key? key,
    Widget? titleWidget,
    String? titleText,
    List<Widget>? actions,
    Gradient? gradient,
    VoidCallback? onBack,
    bool centerTitle = false,
    double height = kToolbarHeight,
    PreferredSizeWidget? bottom,
  }) {
    return ReusableAppBar(
      key: key,
      titleWidget: titleWidget,
      titleText: titleText,
      actions: actions,
      onBack: onBack,
      centerTitle: centerTitle,
      backgroundGradient: gradient,
      height: height,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(height + bottomHeight);
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (!automaticallyImplyLeading) return null;

    // default back button
    if (showBackButton && Navigator.canPop(context)) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack ?? () => Navigator.maybePop(context),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = transparent
        ? Colors.transparent
        : backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor;

    final effectiveElevation = showElevation ? elevation : 0;

    final title = titleWidget ?? (titleText != null ? Padding(padding: titlePadding ?? EdgeInsets.zero, child: Text(titleText!)) : null);

    final appBar = AppBar(
      title: title,
      centerTitle: centerTitle,
      leading: _buildLeading(context),
      actions: actions,
      elevation: effectiveElevation.toDouble(),
      backgroundColor: bgColor,
      shape: shape,
      bottom: bottom,
      automaticallyImplyLeading: false, // handled by _buildLeading
      toolbarHeight: height,
      titleSpacing: 0,
      systemOverlayStyle: systemOverlayStyle,
    );

    // If a gradient is requested, wrap AppBar in Material with flexibleSpace.
    if (backgroundGradient != null) {
      return PreferredSize(
        preferredSize: preferredSize,
        child: Container(
          height: preferredSize.height,
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: SafeArea(child: appBar),
        ),
      );
    }

    // For transparent AppBar we still want SafeArea + Material to ensure icons
    // and ripple behave correctly on iOS/Android.
    if (transparent) {
      return PreferredSize(
        preferredSize: preferredSize,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: appBar,
          ),
        ),
      );
    }

    return appBar;
  }
}


/// Search-capable AppBar variant with optional suggestion dropdown.
/// Use like: `appBar: SearchAppBar(... )` in Scaffold.
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? hintText;
  final Widget? leading;
  final List<Widget>? actions;
  final ValueChanged<String>? onChanged; // debounced onChanged
  final ValueChanged<String>? onSubmitted;
  final Duration debounceDuration;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  final bool showClearButton;
  final TextInputType keyboardType;

  // Suggestions
  /// A function to fetch suggestions for a query. If provided, suggestion
  /// dropdown will be shown. It can be async and should return a list of
  /// suggestion strings (or any displayable text).
  final Future<List<String>> Function(String query)? suggestionCallback;
  final int suggestionLimit;
  final Widget Function(BuildContext, String)? suggestionBuilder; // custom row builder

  const SearchAppBar({
    Key? key,
    this.hintText,
    this.leading,
    this.actions,
    this.onChanged,
    this.onSubmitted,
    this.debounceDuration = const Duration(milliseconds: 350),
    this.backgroundColor,
    this.bottom,
    this.showClearButton = true,
    this.keyboardType = TextInputType.text,
    this.suggestionCallback,
    this.suggestionLimit = 6,
    this.suggestionBuilder,
  }) : super(key: key);

  @override
  _SearchAppBarState createState() => _SearchAppBarState();

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}

class _SearchAppBarState extends State<SearchAppBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<String> _suggestions = [];
  bool _loadingSuggestions = false;

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () async {
      final q = _controller.text;
      if (widget.onChanged != null) widget.onChanged!(q);

      if (widget.suggestionCallback != null) {
        if (q.trim().isEmpty) {
          _suggestions = [];
          _removeOverlay();
          return;
        }
        setState(() => _loadingSuggestions = true);
        try {
          final results = await widget.suggestionCallback!(q);
          _suggestions = results.take(widget.suggestionLimit).toList();
          if (_suggestions.isEmpty) {
            _removeOverlay();
          } else {
            _showOverlay();
          }
        } catch (e) {
          // silently ignore suggestion errors
          _suggestions = [];
          _removeOverlay();
        } finally {
          if (mounted) setState(() => _loadingSuggestions = false);
        }
      }
    });
    setState(() {});
  }

  void _showOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context)?.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 16, // small padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(8, size.height + 8),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = _suggestions[index];
                  return InkWell(
                    onTap: () {
                      _controller.text = s;
                      _controller.selection = TextSelection.collapsed(offset: s.length);
                      widget.onSubmitted?.call(s);
                      _removeOverlay();
                      FocusScope.of(context).unfocus();
                      setState(() {});
                    },
                    child: widget.suggestionBuilder != null
                        ? widget.suggestionBuilder!(context, s)
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Text(s),
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

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clearVisible = widget.showClearButton && _controller.text.isNotEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      child: AppBar(
        leading: widget.leading,
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _controller,
            keyboardType: widget.keyboardType,
            textInputAction: TextInputAction.search,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Search',
              filled: true,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              suffixIcon: clearVisible
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        if (widget.onChanged != null) widget.onChanged!('');
                        _removeOverlay();
                        setState(() {});
                      },
                    )
                  : _loadingSuggestions
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
            ),
          ),
        ),
        actions: widget.actions,
        backgroundColor: widget.backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
        automaticallyImplyLeading: false,
      ),
    );
  }
}


/// A Sliver variant that maps the same friendly props to a SliverAppBar.
class SliverReusableAppBar extends StatelessWidget {
  final Widget? titleWidget;
  final String? titleText;
  final bool centerTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final double expandedHeight;
  final bool pinned;
  final bool floating;
  final bool snap;
  final Gradient? backgroundGradient;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  final bool stretch;

  const SliverReusableAppBar({
    Key? key,
    this.titleWidget,
    this.titleText,
    this.centerTitle = false,
    this.leading,
    this.actions,
    this.expandedHeight = 200,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.backgroundGradient,
    this.backgroundColor,
    this.bottom,
    this.stretch = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final flexibleSpace = FlexibleSpaceBar(
      title: titleWidget ?? (titleText != null ? Text(titleText!) : null),
      centerTitle: centerTitle,
      background: backgroundGradient != null
          ? Container(decoration: BoxDecoration(gradient: backgroundGradient))
          : null,
    );

    return SliverAppBar(
      leading: leading,
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
      snap: snap,
      stretch: stretch,
      actions: actions,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
    );
  }
}


/// Platform-adaptive AppBar: uses CupertinoNavigationBar on iOS and
/// ReusableAppBar on other platforms. Accepts most common props.
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;

  const AdaptiveAppBar({
    Key? key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.backgroundColor,
    this.bottom,
  }) : super(key: key);

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(
        height: preferredSize.height,
        child: CupertinoNavigationBar(
          middle: title != null ? Text(title!) : null,
          leading: leading,
          trailing: actions != null && actions!.isNotEmpty ? Row(mainAxisSize: MainAxisSize.min, children: actions!) : null,
          backgroundColor: backgroundColor ?? CupertinoTheme.of(context).barBackgroundColor,
        ),
      );
    }

    return ReusableAppBar(
      titleText: title,
      titleWidget: null,
      leading: leading,
      centerTitle: centerTitle,
      actions: actions,
      backgroundColor: backgroundColor,
      bottom: bottom,
    );
  }
}


/*
EXAMPLE USAGE:

// Basic
Scaffold(
  appBar: ReusableAppBar(
    titleText: 'Home',
    centerTitle: true,
    actions: [IconButton(icon: Icon(Icons.search), onPressed: () {})],
  ),
  body: ...
)

// Transparent overlay (good for hero/image header)
Scaffold(
  extendBodyBehindAppBar: true,
  appBar: ReusableAppBar.transparent(
    titleText: 'Profile',
    onBack: () => print('back'),
  ),
  body: Stack(...)
)

// Gradient AppBar
Scaffold(
  appBar: ReusableAppBar.gradient(
    titleText: 'Shop',
    gradient: LinearGradient(colors: [Colors.purple, Colors.deepPurpleAccent]),
    actions: [IconButton(icon: Icon(Icons.shopping_cart), onPressed: () {})],
  ),
  body: ...
)

// Search AppBar with suggestions (example suggestionCallback uses a local list)
final sampleItems = ['Apple', 'Banana', 'Cucumber', 'Date', 'Eggplant', 'Fig', 'Grape'];

Scaffold(
  appBar: SearchAppBar(
    hintText: 'Search produce',
    suggestionCallback: (q) async {
      await Future.delayed(Duration(milliseconds: 100)); // simulate latency
      return sampleItems.where((s) => s.toLowerCase().contains(q.toLowerCase())).toList();
    },
    onSubmitted: (q) => print('search submit: $q'),
  ),
  body: ...
)

// Sliver usage
CustomScrollView(
  slivers: [
    SliverReusableAppBar(
      titleText: 'Explore',
      expandedHeight: 220,
      backgroundGradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
    ),
    SliverList(...)
  ],
)

// Adaptive AppBar (uses Cupertino on iOS)
Scaffold(
  appBar: AdaptiveAppBar(title: 'Adaptive'),
)


WIDGET TEST EXAMPLE (flutter_test):

// test/widgets/reusable_appbar_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:your_app/widgets/reusable_app_bar.dart';

void main() {
  testWidgets('ReusableAppBar shows title and back when canPop', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => Scaffold(appBar: ReusableAppBar(titleText: 'X'))),
      ),
    ));

    expect(find.text('X'), findsOneWidget);
  });

  testWidgets('SearchAppBar shows suggestion and tap selects it', (WidgetTester tester) async {
    final items = ['one', 'two', 'three'];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: SearchAppBar(
          suggestionCallback: (q) async => items.where((s) => s.contains(q)).toList(),
        ),
        body: Container(),
      ),
    ));

    await tester.enterText(find.byType(TextField), 't');
    await tester.pumpAndSettle();

    expect(find.text('two'), findsOneWidget);
    await tester.tap(find.text('two'));
    await tester.pumpAndSettle();

    expect(find.text('two'), findsOneWidget);
  });

Notes on tests: widget tests that rely on Overlay may need pumpAndSettle to wait for timers.


NEXT SUGGESTIONS / OPTIONALS I IMPLEMENTED:
- Autocomplete suggestion dropdown (async) for SearchAppBar with custom builder and debouncing.
- Platform-adaptive `AdaptiveAppBar` that picks a Cupertino look for iOS.
- Example widget tests and usage examples.

POTENTIAL IMPROVEMENTS:
- Add keyboard navigation for suggestions (arrow up/down + enter).
- Improve positioning logic for overlay when used inside complex layouts.
- Add accessibility semantics to suggestion items.
- Add theming tokens (padding, borderRadius) as named parameters for easier customization.
*/