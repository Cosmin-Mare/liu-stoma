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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28 * scale),
              side: BorderSide(
                color: Colors.black,
                width: 6 * scale,
              ),
            ),
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: 32 * scale,
              vertical: 16 * scale,
            ),
            textStyle: TextStyle(
              fontSize: 28 * scale,
              fontWeight: FontWeight.w900,
              fontFamily: 'Roboto Slab',
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28 * scale),
              side: BorderSide(
                color: Colors.black,
                width: 5 * scale,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 24 * scale,
              vertical: 12 * scale,
            ),
            textStyle: TextStyle(
              fontSize: 26 * scale,
              fontWeight: FontWeight.w700,
              fontFamily: 'Roboto Slab',
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
        child: child,
      ),
    );
  }
}

