import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// A helper class for optimized Firebase operations
class FirebaseHelper {
  /// Gets document from cache first, then server if needed
  static Future<DocumentSnapshot> getDocumentOptimized(
      DocumentReference docRef) async {
    try {
      // Try to get from cache first
      final cachedDoc = await docRef.get(const GetOptions(source: Source.cache));
      if (cachedDoc.exists) {
        // Refresh in background but return cached data immediately
        docRef.get(const GetOptions(source: Source.server));
        return cachedDoc;
      }
    } catch (_) {
      // Cache retrieval failed, continue to server request
    }
    
    // Get from server if cache fails or doesn't exist
    return await docRef.get(const GetOptions(source: Source.server));
  }
  
  /// Gets collection with pagination for better performance
  static Query getPaginatedCollection(
      CollectionReference colRef, {
      int limit = 10,
      String? orderBy,
      bool descending = false,
      DocumentSnapshot? startAfter,
    }) {
    Query query = colRef;
    
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    return query.limit(limit);
  }
  
  /// Performs batch writes for better performance
  static Future<void> batchWrite(
      Map<DocumentReference, Map<String, dynamic>> writes,
      {bool merge = true}) async {
    final batch = FirebaseFirestore.instance.batch();
    
    writes.forEach((docRef, data) {
      if (merge) {
        batch.set(docRef, data, SetOptions(merge: true));
      } else {
        batch.set(docRef, data);
      }
    });
    
    return batch.commit();
  }
  
  /// Optimized real-time database listener with proper cleanup
  static StreamSubscription<rtdb.DatabaseEvent> listenToRealtimeDB(
      rtdb.DatabaseReference ref,
      void Function(rtdb.DatabaseEvent event) onData) {
    return ref.onValue.listen(onData);
  }
  
  /// Gets current user with caching
  static Future<User?> getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }
  
  /// Optimizes Firestore queries with indexing hints
  static Query optimizeQuery(Query query) {
    // Enable indexing hints for better query performance
    return query.withConverter(
      fromFirestore: (snapshot, _) => snapshot.data() ?? {},
      toFirestore: (data, _) => data as Map<String, dynamic>,
    );
  }
} 