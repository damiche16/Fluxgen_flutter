import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io' show Platform, Directory, File;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Image Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),
      home: const ImageGeneratorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ImageGeneratorScreen extends StatefulWidget {
  const ImageGeneratorScreen({super.key});

  @override
  State<ImageGeneratorScreen> createState() => _ImageGeneratorScreenState();
}

class _ImageGeneratorScreenState extends State<ImageGeneratorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  String? _generatedImageUrl;
  bool _isLoading = false;
  bool _isDownloading = false;
  String _selectedModel = 'flux';
  String _selectedSize = '1024x1024';
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  final Map<String, String> _models = {
    'flux': 'Flux Pro',
    'flux-realism': 'Realism',
    'flux-cablyai': 'CablyAI',
    'flux-anime': 'Anime Style',
    'flux-3d': '3D Render',
    'turbo': 'Turbo Fast',
  };

  final Map<String, String> _sizes = {
    '512x512': '512×512',
    '768x768': '768×768',
    '1024x1024': '1024×1024',
    '1280x720': '1280×720',
    '1920x1080': '1920×1080',
  };

  final List<Map<String, dynamic>> _promptSuggestions = [
    {'text': 'Cyberpunk neon city', 'icon': Icons.location_city, 'color': Color(0xFF00D4FF)},
    {'text': 'Majestic dragon', 'icon': Icons.pets, 'color': Color(0xFFFF6B6B)},
    {'text': 'Space nebula', 'icon': Icons.star, 'color': Color(0xFF4ECDC4)},
    {'text': 'Fantasy forest', 'icon': Icons.forest, 'color': Color(0xFF45B7D1)},
    {'text': 'Futuristic robot', 'icon': Icons.smart_toy, 'color': Color(0xFF96CEB4)},
    {'text': 'Ocean sunset', 'icon': Icons.wb_sunny, 'color': Color(0xFFFECEA8)},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  Future<void> _generateImage() async {
    if (_promptController.text.trim().isEmpty) {
      _showSnackBar('Please enter a prompt to generate an image', const Color(0xFFFF6B6B));
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedImageUrl = null;
    });
    _animationController.reset();

    try {
      final encodedPrompt = Uri.encodeComponent(_promptController.text.trim());
      final dimensions = _selectedSize.split('x');
      final width = dimensions[0];
      final height = dimensions[1];

      final url = 'https://image.pollinations.ai/prompt/$encodedPrompt'
          '?model=$_selectedModel'
          '&width=$width'
          '&height=$height'
          '&enhance=true'
          '&nologo=true'
          '&private=false'
          '&seed=${DateTime.now().millisecondsSinceEpoch}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Flutter App',
          'Accept': 'image/*',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        setState(() {
          _generatedImageUrl = url;
          _isLoading = false;
        });
        _animationController.forward();
        _showSnackBar('✨ Image generated successfully!', const Color(0xFF4ECDC4));
      } else {
        throw Exception('Failed to generate image: HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      try {
        final encodedPrompt = Uri.encodeComponent(_promptController.text.trim());
        final fallbackUrl = 'https://image.pollinations.ai/prompt/$encodedPrompt';

        final fallbackResponse = await http.get(
          Uri.parse(fallbackUrl),
          headers: {
            'User-Agent': 'Flutter App',
            'Accept': 'image/*',
          },
        ).timeout(const Duration(seconds: 30));

        if (fallbackResponse.statusCode == 200 && fallbackResponse.bodyBytes.isNotEmpty) {
          setState(() {
            _generatedImageUrl = fallbackUrl;
            _isLoading = false;
          });
          _animationController.forward();
          _showSnackBar('⚡ Image generated with basic settings!', const Color(0xFFFECEA8));
        } else {
          _showSnackBar('Unable to generate image. Please try a different prompt.', const Color(0xFFFF6B6B));
        }
      } catch (fallbackError) {
        _showSnackBar('Network error. Please check your connection and try again.', const Color(0xFFFF6B6B));
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                color == const Color(0xFF4ECDC4) ? Icons.check_circle_outline :
                color == const Color(0xFFFECEA8) ? Icons.warning_amber_outlined : Icons.error_outline,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _downloadImage() async {
    if (_generatedImageUrl == null) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      if (Platform.isAndroid) {
        // Get Android version
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        
        Permission permission;
        
        // For Android 13+ (API 33+), use photos permission
        if (androidInfo.version.sdkInt >= 33) {
          permission = Permission.photos;
        } 
        // For Android 11-12 (API 30-32), use manageExternalStorage
        else if (androidInfo.version.sdkInt >= 30) {
          permission = Permission.manageExternalStorage;
        } 
        // For older versions, use storage permission
        else {
          permission = Permission.storage;
        }

        var status = await permission.status;
        if (!status.isGranted) {
          status = await permission.request();
          if (!status.isGranted) {
            _showSnackBar('Storage permission is required to download images', const Color(0xFFFF6B6B));
            setState(() {
              _isDownloading = false;
            });
            return;
          }
        }

        final response = await http.get(Uri.parse(_generatedImageUrl!));
        if (response.statusCode == 200) {
          Directory? directory;
          
          // Try to get Downloads directory first
          try {
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              directory = await getExternalStorageDirectory();
            }
          } catch (e) {
            directory = await getExternalStorageDirectory();
          }
          
          // Fallback to app documents directory
          directory ??= await getApplicationDocumentsDirectory();

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'ai_image_$timestamp.jpg';
          final file = File('${directory.path}/$fileName');

          await file.writeAsBytes(response.bodyBytes);

          _showSnackBar('📱 Image downloaded to ${directory.path}/$fileName!', const Color(0xFF4ECDC4));
          HapticFeedback.lightImpact();
        } else {
          _showSnackBar('Failed to download image', const Color(0xFFFF6B6B));
        }
      } else if (Platform.isIOS) {
        // iOS permission handling
        var status = await Permission.photos.status;
        if (!status.isGranted) {
          status = await Permission.photos.request();
          if (!status.isGranted) {
            _showSnackBar('Photos permission is required to download images', const Color(0xFFFF6B6B));
            setState(() {
              _isDownloading = false;
            });
            return;
          }
        }

        final response = await http.get(Uri.parse(_generatedImageUrl!));
        if (response.statusCode == 200) {
          final directory = await getApplicationDocumentsDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'ai_image_$timestamp.jpg';
          final file = File('${directory.path}/$fileName');

          await file.writeAsBytes(response.bodyBytes);

          _showSnackBar('📱 Image downloaded to ${directory.path}/$fileName!', const Color(0xFF4ECDC4));
          HapticFeedback.lightImpact();
        } else {
          _showSnackBar('Failed to download image', const Color(0xFFFF6B6B));
        }
      } else {
        // Desktop platforms
        final response = await http.get(Uri.parse(_generatedImageUrl!));
        if (response.statusCode == 200) {
          Directory? directory;
          final downloadsDir = await getDownloadsDirectory();
          directory = downloadsDir ?? await getApplicationDocumentsDirectory();

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'ai_image_$timestamp.jpg';
          final file = File('${directory.path}/$fileName');

          await file.writeAsBytes(response.bodyBytes);

          _showSnackBar('💻 Image downloaded to ${directory.path}/$fileName!', const Color(0xFF4ECDC4));
        } else {
          _showSnackBar('Failed to download image', const Color(0xFFFF6B6B));
        }
      }
    } catch (e) {
      _showSnackBar('Error downloading image: ${e.toString()}', const Color(0xFFFF6B6B));
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _useSuggestion(String suggestion) {
    _promptController.text = suggestion;
    HapticFeedback.selectionClick();
  }

  Widget _buildGlassCard({required Widget child, double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0.4),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildModernButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isLoading = false,
    bool isSecondary = false,
    required bool isSmallScreen,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isSecondary ? null : LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: isSecondary ? Border.all(color: color.withValues(alpha: 0.3)) : null,
        boxShadow: isSecondary ? null : [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSecondary ? color : Colors.white,
                      ),
                    ),
                  )
                else
                  Icon(
                    icon,
                    color: isSecondary ? color : Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isSecondary ? color : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFF),
              Color(0xFFE8F4FD),
              Color(0xFFF0F8FF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modern Header
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFF3B82F6),
                        Color(0xFF06B6D4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                size: isSmallScreen ? 30 : 40,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AI Image Generator',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 26 : 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Transform your imagination into stunning visuals',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 18,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Prompt Input Section
                _buildGlassCard(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 20.0 : 28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF8B5CF6),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Describe Your Vision',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 17 : 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                              width: 2,
                            ),
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          child: TextField(
                            controller: _promptController,
                            decoration: InputDecoration(
                              hintText: 'A futuristic cityscape with neon lights and flying cars...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: isSmallScreen ? 13 : 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(isSmallScreen ? 14 : 20),
                            ),
                            maxLines: 4,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Quick Ideas',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _promptSuggestions.map((suggestion) {
                            return GestureDetector(
                              onTap: () => _useSuggestion(suggestion['text']),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 10 : 16,
                                  vertical: isSmallScreen ? 7 : 10,
                                ),
                                decoration: BoxDecoration(
                                  color: (suggestion['color'] as Color).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: (suggestion['color'] as Color).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      suggestion['icon'],
                                      size: isSmallScreen ? 13 : 16,
                                      color: suggestion['color'],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      suggestion['text'],
                                      style: TextStyle(
                                        color: suggestion['color'],
                                        fontWeight: FontWeight.w600,
                                        fontSize: isSmallScreen ? 11 : 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Settings Section - Responsive
                isSmallScreen
                    ? Column(
                        children: [
                          _buildGlassCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.psychology_outlined,
                                          color: Color(0xFF3B82F6),
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'AI Model',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withValues(alpha: 0.8),
                                      border: Border.all(
                                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedModel,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      ),
                                      items: _models.entries.map((entry) {
                                        return DropdownMenuItem(
                                          value: entry.key,
                                          child: Text(
                                            entry.value,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedModel = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildGlassCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.aspect_ratio_outlined,
                                          color: Color(0xFF06B6D4),
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Image Size',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withValues(alpha: 0.8),
                                      border: Border.all(
                                        color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedSize,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      ),
                                      items: _sizes.entries.map((entry) {
                                        return DropdownMenuItem(
                                          value: entry.key,
                                          child: Text(
                                            entry.value,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedSize = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildGlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.psychology_outlined,
                                            color: Color(0xFF3B82F6),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Flexible(
                                          child: Text(
                                            'AI Model',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: Colors.white.withValues(alpha: 0.8),
                                        border: Border.all(
                                          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedModel,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        ),
                                        items: _models.entries.map((entry) {
                                          return DropdownMenuItem(
                                            value: entry.key,
                                            child: Text(
                                              entry.value,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedModel = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildGlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.aspect_ratio_outlined,
                                            color: Color(0xFF06B6D4),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Flexible(
                                          child: Text(
                                            'Image Size',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: Colors.white.withValues(alpha: 0.8),
                                        border: Border.all(
                                          color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedSize,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        ),
                                        items: _sizes.entries.map((entry) {
                                          return DropdownMenuItem(
                                            value: entry.key,
                                            child: Text(
                                              entry.value,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedSize = value!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                const SizedBox(height: 24),

                // Generate Button
                _buildModernButton(
                  text: _isLoading ? 'Creating Magic...' : 'Generate Image',
                  icon: Icons.auto_awesome,
                  onPressed: _generateImage,
                  color: const Color(0xFF8B5CF6),
                  isLoading: _isLoading,
                  isSmallScreen: isSmallScreen,
                ),

                const SizedBox(height: 24),

                // Loading State
                if (_isLoading)
                  _buildGlassCard(
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 32.0 : 48.0),
                      child: Column(
                        children: [
                          SpinKitRing(
                            color: const Color(0xFF8B5CF6),
                            size: isSmallScreen ? 50.0 : 80.0,
                            lineWidth: 4.0,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Crafting your masterpiece...',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'AI is working its magic ✨',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 16,
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Generated Image Display - Completely Redesigned
                if (_generatedImageUrl != null && !_isLoading)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.9),
                              Colors.white.withValues(alpha: 0.6),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Padding(
                              padding: EdgeInsets.all(isSmallScreen ? 18.0 : 24.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Your Masterpiece',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 18 : 24,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF1F2937),
                                          ),
                                        ),
                                        Text(
                                          'Generated with AI magic ✨',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 13 : 16,
                                            color: const Color(0xFF6B7280),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Image Container
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 18.0 : 24.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxHeight: isSmallScreen ? 360 : 500,
                                      minHeight: isSmallScreen ? 180 : 250,
                                    ),
                                    child: Image.network(
                                      _generatedImageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          height: isSmallScreen ? 280 : 400,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                                const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SpinKitRing(
                                                  color: const Color(0xFF8B5CF6),
                                                  size: isSmallScreen ? 35.0 : 50.0,
                                                  lineWidth: 3.0,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Loading your image...',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 15 : 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF8B5CF6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: isSmallScreen ? 180 : 250,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                                                const Color(0xFFFF8E8E).withValues(alpha: 0.1),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Icon(
                                                  Icons.error_outline,
                                                  size: isSmallScreen ? 35 : 50,
                                                  color: const Color(0xFFFF6B6B),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Failed to load image',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 16 : 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFFFF6B6B),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Please try generating again',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 13 : 16,
                                                  color: const Color(0xFF6B7280),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              _buildModernButton(
                                                text: 'Retry',
                                                icon: Icons.refresh,
                                                onPressed: _generateImage,
                                                color: const Color(0xFFFF6B6B),
                                                isSmallScreen: isSmallScreen,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Prompt Display
                            Padding(
                              padding: EdgeInsets.all(isSmallScreen ? 18.0 : 24.0),
                              child: Container(
                                padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                                      const Color(0xFF3B82F6).withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.format_quote,
                                        color: Color(0xFF8B5CF6),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _promptController.text,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 13 : 16,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF374151),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Action Buttons
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                isSmallScreen ? 18.0 : 24.0,
                                0,
                                isSmallScreen ? 18.0 : 24.0,
                                isSmallScreen ? 18.0 : 24.0,
                              ),
                              child: Column(
                                children: [
                                  _buildModernButton(
                                    text: _isDownloading ? 'Downloading...' : 'Download',
                                    icon: Icons.download_outlined,
                                    onPressed: _downloadImage,
                                    color: const Color(0xFF06B6D4),
                                    isLoading: _isDownloading,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  _buildModernButton(
                                    text: 'Generate New',
                                    icon: Icons.refresh,
                                    onPressed: _generateImage,
                                    color: const Color(0xFF10B981),
                                    isSecondary: true,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
