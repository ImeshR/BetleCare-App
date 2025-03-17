import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../widgets/bottom_nav_bar.dart';

class DiseasePhotoManagementPage extends StatefulWidget {
  const DiseasePhotoManagementPage({super.key});

  @override
  State<DiseasePhotoManagementPage> createState() =>
      _DiseasePhotoManagementPageState();
}

class _DiseasePhotoManagementPageState
    extends State<DiseasePhotoManagementPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _capturedImagePath;
  Map<String, dynamic>? _predictionResult;
  String? _errorMessage;

  // Disease information map
  final Map<String, Map<String, dynamic>> _diseaseInfo = {
    'Bacterial leaf blight': {
      'sinhalaName': 'බැක්ටීරියා පත්‍ර අංගමාරය',
      'description':
          'බැක්ටීරියා පත්‍ර අංගමාරය යනු බැක්ටීරියා මගින් ඇති වන රෝගයකි. මෙය වී වගාවට බරපතල හානි සිදු කරයි. පත්‍ර මත කහ පැහැති ඉරි ඇති වීමෙන් මෙය හඳුනාගත හැකිය.',
      'treatments': [
        'රෝගයට ඔරොත්තු දෙන වී ප්‍රභේද වගා කරන්න',
        'නයිට්‍රජන් පොහොර භාවිතය අඩු කරන්න',
        'කොපර් පදනම් කරගත් දිලීර නාශක යොදන්න',
        'රෝගී ශාක ඉවත් කර විනාශ කරන්න'
      ],
      'color': Colors.orange,
      'icon': Icons.grass,
    },
    'Brown Spots': {
      'sinhalaName': 'දුඹුරු පැල්ලම්',
      'description':
          'දුඹුරු පැල්ලම් රෝගය දිලීර මගින් ඇති වන රෝගයකි. පත්‍ර මත දුඹුරු පැහැති, රවුම් හෝ ඉලිප්සාකාර පැල්ලම් ඇති වීමෙන් මෙය හඳුනාගත හැකිය.',
      'treatments': [
        'රෝගී පත්‍ර ඉවත් කර විනාශ කරන්න',
        'දිලීර නාශක යොදන්න',
        'ශාක අතර වාතාශ්‍රය වැඩි කරන්න',
        'පත්‍ර තෙමීම වළක්වන්න'
      ],
      'color': Colors.brown,
      'icon': Icons.blur_circular,
    },
    'Firefly disease': {
      'sinhalaName': 'විදුරුමස්සා රෝගය',
      'description':
          'විදුරුමස්සා රෝගය වෛරස් මගින් ඇති වන රෝගයකි. පත්‍ර මත කහ පැහැති පැල්ලම් සහ ශාකයේ වර්ධනය අඩාල වීමෙන් මෙය හඳුනාගත හැකිය.',
      'treatments': [
        'රෝගී ශාක ඉවත් කර විනාශ කරන්න',
        'කෘමි නාශක භාවිතයෙන් වාහක පාලනය කරන්න',
        'රෝගයට ඔරොත්තු දෙන ප්‍රභේද වගා කරන්න',
        'ශාක අතර ප්‍රමාණවත් පරතරයක් තබා ගන්න'
      ],
      'color': Colors.amber,
      'icon': Icons.wb_incandescent,
    },
    'Healthy': {
      'sinhalaName': 'නිරෝගී',
      'description':
          'ශාකය නිරෝගී තත්ත්වයේ පවතී. කිසිදු රෝග ලක්ෂණයක් දක්නට නොමැත.',
      'treatments': [
        'නිසි ලෙස ජලය සැපයීම දිගටම කරගෙන යන්න',
        'නිසි ලෙස පොහොර යෙදීම කරගෙන යන්න',
        'නියමිත කාල පරාසයන්හිදී පළිබෝධ පාලනය කරන්න',
        'ශාක අතර ප්‍රමාණවත් පරතරයක් පවත්වා ගන්න'
      ],
      'color': Colors.green,
      'icon': Icons.check_circle,
    },
    'Red spider mite': {
      'sinhalaName': 'රතු මකුළු මයිටාව',
      'description':
          'රතු මකුළු මයිටාව ශාක පත්‍ර වල රස උරා බොන කුඩා කෘමියෙකි. පත්‍ර මත කහ පැහැති තිත් සහ සියුම් දැල් ඇති වීමෙන් මෙය හඳුනාගත හැකිය.',
      'treatments': [
        'සබන් දිය ස්ප්‍රේ කිරීම',
        'නීම් තෙල් භාවිතා කිරීම',
        'ජෛව පාලන ක්‍රම භාවිතා කිරීම',
        'අධික ලෙස හානි වූ පත්‍ර ඉවත් කිරීම'
      ],
      'color': Colors.red,
      'icon': Icons.bug_report,
    },
  };

  Future<void> _takePicture() async {
    setState(() {
      _isLoading = true;
      _predictionResult = null;
      _errorMessage = null;
    });

    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ඡායාරූපය සාර්ථකව ගන්නා ලදී')),
        );

        setState(() {
          _capturedImagePath = photo.path;
        });

        // Send image to prediction API
        await _sendImageForPrediction(photo);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadPhoto() async {
    setState(() {
      _isLoading = true;
      _predictionResult = null;
      _errorMessage = null;
    });

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ඡායාරූපය සාර්ථකව උඩුගත කරන ලදී')),
        );

        setState(() {
          _capturedImagePath = image.path;
        });

        // Send image to prediction API
        await _sendImageForPrediction(image);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _sendImageForPrediction(XFile imageFile) async {
    try {
      // Create multipart request with the new API endpoint
      final apiUrl = dotenv.env['DISEASE_PREDICT']?.trim();
        if (apiUrl == null || apiUrl.isEmpty) {
          throw Exception('API URL is missing');
        }
        
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Get file extension
      final String fileExtension = imageFile.path.split('.').last.toLowerCase();
      final String mimeType = fileExtension == 'png'
          ? 'image/png'
          : fileExtension == 'jpg' || fileExtension == 'jpeg'
              ? 'image/jpeg'
              : 'application/octet-stream';

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // Keep the field name as 'image' as specified
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Send request
      final response = await request.send();

      // Get response
      final responseData = await response.stream.bytesToString();
      print("Test response, $responseData");
      if (response.statusCode == 200) {
        // Parse response
        final Map<String, dynamic> result = json.decode(responseData);

        // Ensure we have a predicted_class field
        if (result.containsKey('predicted_class')) {
          setState(() {
            _predictionResult = result;
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid response format: missing predicted_class');
        }
      } else {
        throw Exception(
            'Failed to predict disease: ${response.statusCode} - ${responseData}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('රෝග හඳුනාගැනීම'),
        backgroundColor: Colors.green.shade100,
      ),
      body: _capturedImagePath != null &&
              (_predictionResult != null || _isLoading)
          ? _buildPredictionResult()
          : _buildPhotoOptions(),
    );
  }

  Widget _buildPhotoOptions() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ඔබගේ ශාක රෝග හඳුනා ගැනීමට ඡායාරූප ගන්න හෝ උඩුගත කරන්න',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            _buildCard(
              title: 'ඡායාරූපයක් ගන්න',
              description: 'ඔබගේ ශාකයේ රෝග ලක්ෂණ ඡායාරූපයක් ගන්න',
              color: Colors.green.shade100,
              imagePath: 'assets/images/disease/DD4.png',
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.green.shade100,
                ],
              ),
              icon: Icons.camera_alt,
              onTap: _isLoading ? null : _takePicture,
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'ඡායාරූපයක් උඩුගත කරන්න',
              description: 'ඔබගේ ගැලරියෙන් ඡායාරූපයක් තෝරන්න',
              color: Colors.purple.shade100,
              imagePath: 'assets/images/disease/DD5.png',
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade50,
                  Colors.purple.shade100,
                ],
              ),
              icon: Icons.photo_library,
              onTap: _isLoading ? null : _uploadPhoto,
            ),
            if (_isLoading) ...[
              const SizedBox(height: 32),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('කරුණාකර රැඳී සිටින්න...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionResult() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isLoading
                  ? 'ඔබගේ ඡායාරූපය විශ්ලේෂණය කරමින්...'
                  : _errorMessage != null
                      ? 'දෝෂයක් ඇති විය'
                      : 'රෝග විශ්ලේෂණ ප්‍රතිඵල',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 24),
            // Display the captured or uploaded image
            if (_capturedImagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_capturedImagePath!),
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Text('ඡායාරූපය පෙන්විය නොහැක'),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Show loading, error, or results
            if (_isLoading)
              _buildLoadingCard()
            else if (_errorMessage != null)
              _buildErrorCard()
            else if (_predictionResult != null)
              _buildResultCard(),

            const SizedBox(height: 24),

            // Button to try again
            if (!_isLoading)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _capturedImagePath = null;
                      _predictionResult = null;
                      _errorMessage = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('වෙනත් ඡායාරූපයක් උත්සාහ කරන්න'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'රෝග විශ්ලේෂණය කරමින්...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          Text(
            'ඔබගේ ඡායාරූපය විශ්ලේෂණය කරමින් පවතී. මෙය තත්පර කිහිපයක් ගත විය හැකිය.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[700],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'දෝෂයක් ඇති විය',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'රෝග විශ්ලේෂණය කිරීමේදී දෝෂයක් ඇති විය. කරුණාකර පසුව නැවත උත්සාහ කරන්න.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    // Extract prediction data
    final String? diseaseName = _predictionResult?['predicted_class'];
    final double confidence =
        _predictionResult?['confidence']?.toDouble() ?? 95.0;

    // Get disease info from our map
    final diseaseInfo = diseaseName != null ? _diseaseInfo[diseaseName] : null;

    // Set default values if disease not found in our map
    final String sinhalaName = diseaseInfo?['sinhalaName'] ?? 'නොදන්නා රෝගය';
    final String description = diseaseInfo?['description'] ?? 'විස්තරයක් නොමැත';
    final List<dynamic> treatments =
        diseaseInfo?['treatments'] ?? ['නිර්දේශිත ප්‍රතිකාර නොමැත'];
    final Color diseaseColor = (diseaseInfo?['color'] as Color?) ?? Colors.grey;
    final IconData diseaseIcon =
        (diseaseInfo?['icon'] as IconData?) ?? Icons.help_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                diseaseIcon,
                color: diseaseColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'හඳුනාගත් රෝගය',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Disease name with confidence
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: diseaseColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: diseaseColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      diseaseIcon,
                      color: diseaseColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sinhalaName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          if (diseaseName != null && diseaseName != sinhalaName)
                            Text(
                              diseaseName,
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: confidence / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(diseaseColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'විශ්වාසනීයත්වය: ${confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Description
          const SizedBox(height: 16),
          Text(
            'විස්තරය',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),

          // Treatments
          const SizedBox(height: 16),
          Text(
            'නිර්දේශිත ප්‍රතිකාර',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          ...treatments
              .map((treatment) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_right,
                          color: diseaseColor,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            treatment.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),

          // Action button for treatment scheduling if not healthy
          if (diseaseName != 'Healthy') ...[
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to treatment scheduling page
                  Navigator.pop(context); // Go back to main screen
                  // Add navigation to treatment scheduling page here
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('ප්‍රතිකාර සැලසුමක් සාදන්න'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: diseaseColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String description,
    required Color color,
    String? imagePath,
    required Gradient gradient,
    required IconData icon,
    required Function()? onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: imagePath != null
                        ? Image.asset(
                            imagePath,
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          )
                        : Icon(
                            icon,
                            size: 60,
                            color: color
                                .withRed(color.red - 40)
                                .withGreen(color.green - 40)
                                .withBlue(color.blue - 40),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
