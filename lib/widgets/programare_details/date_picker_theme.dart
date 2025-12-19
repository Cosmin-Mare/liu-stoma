import 'package:flutter/material.dart';

class DatePickerThemeHelper {
  static Widget buildDatePickerTheme(BuildContext context, double scale, Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        datePickerTheme: DatePickerThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40 * scale),
            side: BorderSide(
              color: Colors.black,
              width: 7 * scale,
            ),
          ),
        ),
        colorScheme: ColorScheme.light(
          primary: Colors.green[600]!,
          onPrimary: Colors.white,
          onSurface: Colors.black,
          surface: Colors.white,
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            fontSize: 32 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            fontFamily: 'Roboto Slab',
          ),
          bodyLarge: TextStyle(
            fontSize: 28 * scale,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Roboto Slab',
          ),
          bodyMedium: TextStyle(
            fontSize: 26 * scale,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Roboto Slab',
          ),
          labelLarge: TextStyle(
            fontSize: 28 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            fontFamily: 'Roboto Slab',
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40 * scale),
            side: BorderSide(
              color: Colors.black,
              width: 7 * scale,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28 * scale),
            side: BorderSide(
              color: Colors.black,
              width: 5 * scale,
            ),
          ),
          elevation: 0,
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.green[600]!),
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28 * scale),
                side: BorderSide(
                  color: Colors.black,
                  width: 6 * scale,
                ),
              ),
            ),
            elevation: MaterialStateProperty.all<double>(0),
            padding: MaterialStateProperty.all<EdgeInsets>(
              EdgeInsets.symmetric(
                horizontal: 40 * scale,
                vertical: 20 * scale,
              ),
            ),
            textStyle: MaterialStateProperty.all<TextStyle>(
              TextStyle(
                fontSize: 32 * scale,
                fontWeight: FontWeight.w900,
                fontFamily: 'Roboto Slab',
              ),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28 * scale),
                side: BorderSide(
                  color: Colors.black,
                  width: 6 * scale,
                ),
              ),
            ),
            padding: MaterialStateProperty.all<EdgeInsets>(
              EdgeInsets.symmetric(
                horizontal: 40 * scale,
                vertical: 20 * scale,
              ),
            ),
            textStyle: MaterialStateProperty.all<TextStyle>(
              TextStyle(
                fontSize: 32 * scale,
                fontWeight: FontWeight.w900,
                fontFamily: 'Roboto Slab',
              ),
            ),
          ),
        ),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: BoxConstraints(
          maxWidth: 800 * scale,
          minHeight: 600 * scale,
        ),
        child: _DatePickerButtonWrapper(
          scale: scale,
          child: child,
        ),
      ),
    );
  }
}

class _DatePickerButtonWrapper extends StatelessWidget {
  final double scale;
  final Widget child;

  const _DatePickerButtonWrapper({
    required this.scale,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Since both buttons are TextButtons and we can't differentiate them via theme,
    // we need to wrap the date picker and replace buttons individually.
    // The OK button is typically the last button in the action buttons row.
    return _ButtonFinder(
      scale: scale,
      child: child,
    );
  }
}

class _ButtonFinder extends StatelessWidget {
  final double scale;
  final Widget child;

  const _ButtonFinder({
    required this.scale,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        // Don't set backgroundColor on TextButtonTheme - we'll handle it manually
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28 * scale),
                side: BorderSide(
                  color: Colors.black,
                  width: 6 * scale,
                ),
              ),
            ),
            padding: MaterialStateProperty.all<EdgeInsets>(
              EdgeInsets.symmetric(
                horizontal: 40 * scale,
                vertical: 20 * scale,
              ),
            ),
            textStyle: MaterialStateProperty.all<TextStyle>(
              TextStyle(
                fontSize: 32 * scale,
                fontWeight: FontWeight.w900,
                fontFamily: 'Roboto Slab',
              ),
            ),
          ),
        ),
        // Style ElevatedButton as green (in case OK button uses it)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.green[600]!),
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28 * scale),
                side: BorderSide(
                  color: Colors.black,
                  width: 6 * scale,
                ),
              ),
            ),
            elevation: MaterialStateProperty.all<double>(0),
            padding: MaterialStateProperty.all<EdgeInsets>(
              EdgeInsets.symmetric(
                horizontal: 40 * scale,
                vertical: 20 * scale,
              ),
            ),
            textStyle: MaterialStateProperty.all<TextStyle>(
              TextStyle(
                fontSize: 32 * scale,
                fontWeight: FontWeight.w900,
                fontFamily: 'Roboto Slab',
              ),
            ),
          ),
        ),
      ),
      child: _ButtonReplacer(
        scale: scale,
        child: child,
      ),
    );
  }
}

class _ButtonReplacer extends StatelessWidget {
  final double scale;
  final Widget child;

  const _ButtonReplacer({
    required this.scale,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _replaceButtons(child);
  }

  Widget _replaceButtons(Widget widget) {
    if (widget is Row) {
      // Find TextButtons in the Row and replace them
      final children = widget.children;
      final replacedChildren = <Widget>[];
      
      for (int i = 0; i < children.length; i++) {
        final child = children[i];
        if (child is TextButton) {
          // First button (Cancel) = grey, Last button (OK) = green
          final isLastButton = i == children.length - 1 || 
            (i < children.length - 1 && children[i + 1] is! TextButton);
          final buttonColor = isLastButton ? Colors.green[600]! : Colors.grey[400]!;
          
          replacedChildren.add(
            Container(
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(28 * scale),
                border: Border.all(
                  color: Colors.black,
                  width: 6 * scale,
                ),
              ),
              child: TextButton(
                onPressed: child.onPressed,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  overlayColor: MaterialStateProperty.all<Color>(
                    buttonColor.withOpacity(0.2),
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28 * scale),
                    ),
                  ),
                  padding: MaterialStateProperty.all<EdgeInsets>(
                    EdgeInsets.symmetric(
                      horizontal: 40 * scale,
                      vertical: 20 * scale,
                    ),
                  ),
                  textStyle: MaterialStateProperty.all<TextStyle>(
                    TextStyle(
                      fontSize: 32 * scale,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Roboto Slab',
                    ),
                  ),
                ),
                child: child.child ?? const SizedBox(),
              ),
            ),
          );
        } else {
          replacedChildren.add(_replaceButtons(child));
        }
      }
      
      return Row(
        mainAxisAlignment: widget.mainAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
        crossAxisAlignment: widget.crossAxisAlignment,
        children: replacedChildren,
      );
    } else if (widget is Column) {
      final children = widget.children;
      final replacedChildren = children.map((child) => _replaceButtons(child)).toList();
      return Column(
        mainAxisAlignment: widget.mainAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
        crossAxisAlignment: widget.crossAxisAlignment,
        children: replacedChildren,
      );
    } else if (widget is Builder) {
      return Builder(
        builder: (context) => _replaceButtons(widget.builder(context)),
      );
    }
    
    return widget;
  }
}

