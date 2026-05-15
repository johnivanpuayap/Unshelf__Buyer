import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:unshelf_buyer/services/image_picker_service.dart';

class ImagePickerServiceImpl implements ImagePickerService {
  ImagePickerServiceImpl({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    return image.readAsBytes();
  }
}
