import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<bool> requestPhonePermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  Future<bool> requestPhotoLibraryPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  Future<bool> requestAllPermissions() async {
    final camera = await requestCameraPermission();
    final storage = await requestStoragePermission();
    final phone = await requestPhonePermission();
    final photos = await requestPhotoLibraryPermission();

    return camera && storage && phone && photos;
  }

  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  Future<bool> checkStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  Future<bool> checkPhonePermission() async {
    final status = await Permission.phone.status;
    return status.isGranted;
  }

  Future<bool> checkPhotoLibraryPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  Future<bool> checkAllPermissions() async {
    final camera = await checkCameraPermission();
    final storage = await checkStoragePermission();
    final phone = await checkPhonePermission();
    final photos = await checkPhotoLibraryPermission();

    return camera && storage && phone && photos;
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }
} 