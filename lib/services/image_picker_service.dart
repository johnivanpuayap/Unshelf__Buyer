import 'dart:typed_data';

/// Abstraction over `image_picker` so viewmodels can be tested without the plugin.
abstract class ImagePickerService {
  /// Opens the gallery picker and returns the chosen image's bytes, or null
  /// if the user cancels.
  Future<Uint8List?> pickImageFromGallery();
}
