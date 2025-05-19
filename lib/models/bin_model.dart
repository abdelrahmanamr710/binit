import 'package:cloud_firestore/cloud_firestore.dart';

class BinModel {
  final String binId;
  final double plasticMaxCapacity;
  final double metalMaxCapacity;
  final double plasticTotalWeight;
  final double metalTotalWeight;
  final int plasticEmptiedCount;
  final int metalEmptiedCount;
  final DateTime? plasticLastEmptied;
  final DateTime? metalLastEmptied;

  BinModel({
    required this.binId,
    this.plasticMaxCapacity = 50.0, // Default 50kg
    this.metalMaxCapacity = 30.0,   // Default 30kg
    this.plasticTotalWeight = 0.0,
    this.metalTotalWeight = 0.0,
    this.plasticEmptiedCount = 0,
    this.metalEmptiedCount = 0,
    this.plasticLastEmptied,
    this.metalLastEmptied,
  });

  factory BinModel.fromJson(Map<String, dynamic> json) {
    return BinModel(
      binId: json['binId'] as String,
      plasticMaxCapacity: (json['plastic_max_capacity'] as num?)?.toDouble() ?? 50.0,
      metalMaxCapacity: (json['metal_max_capacity'] as num?)?.toDouble() ?? 30.0,
      plasticTotalWeight: (json['plastic_total_weight'] as num?)?.toDouble() ?? 0.0,
      metalTotalWeight: (json['metal_total_weight'] as num?)?.toDouble() ?? 0.0,
      plasticEmptiedCount: json['plastic_emptied_count'] as int? ?? 0,
      metalEmptiedCount: json['metal_emptied_count'] as int? ?? 0,
      plasticLastEmptied: json['plastic_last_emptied'] != null 
          ? (json['plastic_last_emptied'] as Timestamp).toDate()
          : null,
      metalLastEmptied: json['metal_last_emptied'] != null 
          ? (json['metal_last_emptied'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'binId': binId,
      'plastic_max_capacity': plasticMaxCapacity,
      'metal_max_capacity': metalMaxCapacity,
      'plastic_total_weight': plasticTotalWeight,
      'metal_total_weight': metalTotalWeight,
      'plastic_emptied_count': plasticEmptiedCount,
      'metal_emptied_count': metalEmptiedCount,
      'plastic_last_emptied': plasticLastEmptied,
      'metal_last_emptied': metalLastEmptied,
    };
  }
} 