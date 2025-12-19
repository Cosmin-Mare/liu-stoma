import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';

/// A class representing a procedura entry form with controllers for name, cost, and multiplier.
/// Used by both the programare details page and add programare modal.
class ProceduraEntry {
  final TextEditingController numeController;
  final TextEditingController costController;
  final TextEditingController multiplicatorController;

  ProceduraEntry({
    String nume = '',
    double cost = 0,
    int multiplicator = 1,
  })  : numeController = TextEditingController(text: nume),
        costController = TextEditingController(text: cost > 0 ? cost.toString() : ''),
        multiplicatorController = TextEditingController(text: multiplicator.toString());

  void dispose() {
    numeController.dispose();
    costController.dispose();
    multiplicatorController.dispose();
  }

  Procedura toProcedura() {
    return Procedura(
      nume: numeController.text.trim(),
      cost: double.tryParse(costController.text.trim()) ?? 0.0,
      multiplicator: int.tryParse(multiplicatorController.text.trim()) ?? 1,
    );
  }

  bool get isValid => numeController.text.trim().isNotEmpty;
  
  double get calculatedCost {
    final cost = double.tryParse(costController.text.trim()) ?? 0;
    final mult = int.tryParse(multiplicatorController.text.trim()) ?? 1;
    return cost * mult;
  }
}

/// Calculates the total cost from a list of ProceduraEntry
double calculateTotalCost(List<ProceduraEntry> entries) {
  double total = 0;
  for (var entry in entries) {
    total += entry.calculatedCost;
  }
  return total;
}

/// Creates ProceduraEntry list from existing Procedura list
List<ProceduraEntry> createEntriesFromProceduri(List<Procedura> proceduri) {
  if (proceduri.isEmpty) {
    return [ProceduraEntry()];
  }
  return proceduri.map((p) => ProceduraEntry(
    nume: p.nume,
    cost: p.cost,
    multiplicator: p.multiplicator,
  )).toList();
}

