import 'package:flutter/material.dart';

class PatientSearchBar extends StatefulWidget {
  final double scale;
  final double maxWidth;
  final double horizontalPadding;
  final ValueNotifier<String> searchQueryNotifier;
  final int? filteredCount;
  final VoidCallback? onAddPatient;

  const PatientSearchBar({
    super.key,
    required this.scale,
    required this.maxWidth,
    required this.horizontalPadding,
    required this.searchQueryNotifier,
    this.filteredCount,
    this.onAddPatient,
  });

  @override
  State<PatientSearchBar> createState() => _PatientSearchBarState();
}

class _PatientSearchBarState extends State<PatientSearchBar>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      widget.searchQueryNotifier.value = query;
      if (query.isNotEmpty) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleAddPatient() {
    if (widget.onAddPatient != null) {
      widget.onAddPatient!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.maxWidth < 800;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: ValueListenableBuilder<String>(
            valueListenable: widget.searchQueryNotifier,
            builder: (context, searchQuery, child) {
              final showAddButton = searchQuery.isNotEmpty &&
                  (widget.filteredCount == null || widget.filteredCount == 0);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: (isMobile ? 52 : 34) *
                              widget.scale, // even bigger text on mobile
                          fontWeight: FontWeight.w700,
                        ),
                        cursorColor: Colors.black,
                        onSubmitted: (value) {
                          if (showAddButton && widget.onAddPatient != null) {
                            _handleAddPatient();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Caută pacienți',
                          hintStyle: TextStyle(
                            color: Colors.black54,
                            fontSize: (isMobile ? 48 : 34) *
                                widget.scale, // even bigger hint on mobile
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 28 * widget.scale,
                            // Make the bar noticeably taller on mobile
                            vertical:
                                (isMobile ? 30 : 18) * widget.scale, // taller on mobile
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32 * widget.scale),
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: isMobile ? 4.5 : 7,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(32 * widget.scale),
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: isMobile ? 4.5 : 7,
                            ),
                          ),
                          suffixIcon: (showAddButton && !isMobile)
                              ? GestureDetector(
                                  onTap: _handleAddPatient,
                                  child: Container(
                                    margin: EdgeInsets.all(12 * widget.scale),
                                    decoration: BoxDecoration(
                                      color: Colors.green[600],
                                      borderRadius:
                                          BorderRadius.circular(20 * widget.scale),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 5 * widget.scale,
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24 * widget.scale,
                                      vertical: 12 * widget.scale,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          size: 36 * widget.scale,
                                          color: Colors.white,
                                          weight: 900,
                                        ),
                                        SizedBox(width: 8 * widget.scale),
                                        Text(
                                          'Adaugă pacient',
                                          style: TextStyle(
                                            fontSize: 28 * widget.scale,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.only(
                                    right: (isMobile ? 16 : 8) * widget.scale,
                                  ),
                                  child: Icon(
                                    Icons.search,
                                    color: Colors.black,
                                    size: isMobile
                                        ? 32
                                        : 44, // smaller icon on mobile
                                  ),
                                ),
                          suffixIconConstraints: BoxConstraints(
                            minWidth: (showAddButton && !isMobile)
                                ? 200 * widget.scale
                                : (isMobile ? 80 : 90) * widget.scale,
                            minHeight: (showAddButton && !isMobile)
                                ? 110 * widget.scale
                                : (isMobile ? 80 : 90) * widget.scale,
                          ),
                        ),
                      );
                    },
                  ),
                  // Show button below search bar on mobile
                  if (showAddButton && isMobile)
                    Padding(
                      padding: EdgeInsets.only(top: 16 * widget.scale),
                      child: GestureDetector(
                        onTap: _handleAddPatient,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius:
                                BorderRadius.circular(20 * widget.scale),
                            border: Border.all(
                              color: Colors.black,
                              width: 10 * widget.scale,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24 * widget.scale,
                            vertical: 16 * widget.scale,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 80 * widget.scale,
                                color: Colors.white,
                                weight: 900,
                              ),
                              SizedBox(width: 12 * widget.scale),
                              Text(
                                'Adaugă pacient',
                                style: TextStyle(
                                  fontSize: 80 * widget.scale,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

