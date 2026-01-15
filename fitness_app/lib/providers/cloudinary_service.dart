import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // 1. CONFIGURATION
  final String cloudName = "dnhbv4luv"; 
  final String uploadPreset = "fitness_user_upload"; 

  // 2. UPLOAD FUNCTION
  Future<String?> uploadImage(File? imageFile) async {
    if (imageFile == null) return null;

    try {
      // POST request URL
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      // Prepare the request
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset // Authentication without Secret
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // Send the request
      final response = await request.send();

      // Read response
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);

      if (response.statusCode == 200) {
        // Success: Return the secure URL
        return jsonMap['secure_url'] as String;
      } else {
        print("Cloudinary Upload Error: ${jsonMap['error']['message']}");
        return null;
      }
    } catch (e) {
      print("Error uploading to Cloudinary: $e");
      return null;
    }
  }
}