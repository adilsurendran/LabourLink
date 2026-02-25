import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _feedbackController = TextEditingController();

  // State variables
  double _rating = 3.0;
  bool _isSubmitting = false;

  // Animation
  late final AnimationController _controller;

  // Theme Colors
  final Color _primaryColor = const Color(0xFF4A00E0);

  // Dynamic labels based on rating
  final Map<int, String> _ratingLabels = {
    1: "Oh no! What went wrong?",
    2: "We can do better.",
    3: "Thanks! How can we improve?",
    4: "Great! Anything else?",
    5: "Awesome! We love hearing that!",
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Helper to get Color based on rating
  Color _getRatingColor() {
    if (_rating <= 2) return Colors.redAccent;
    if (_rating == 3) return Colors.amber;
    return Colors.green;
  }

  // Helper to get Icon based on rating
  IconData _getRatingIcon() {
    if (_rating <= 2) return Icons.sentiment_dissatisfied_rounded;
    if (_rating == 3) return Icons.sentiment_neutral_rounded;
    if (_rating == 4) return Icons.sentiment_satisfied_alt_rounded;
    return Icons.sentiment_very_satisfied_rounded;
  }

  Future<void> _submitFeedback() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();

    if (_feedbackController.text.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please write a few words about your experience.",
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate Network API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isSubmitting = false);
    _feedbackController.clear();

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.elasticOut,
                ),
                child: const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Thank You!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your feedback helps us improve LabourLink for everyone.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    setState(() => _rating = 0); // Reset rating
                    _controller.reset();
                    _controller.forward();
                  },
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Review & Feedback",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. Animated Gradient Background
          const AnimatedGradientBackground(),

          // 2. Floating Background Shapes
          Positioned(
            top: -50,
            right: -50,
            child: _buildBackgroundShape(200, Colors.white.withOpacity(0.1)),
          ),
          Positioned(
            bottom: 80,
            left: -60,
            child: _buildBackgroundShape(250, Colors.white.withOpacity(0.05)),
          ),

          // 3. Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 100,
                bottom: 40,
                left: 20,
                right: 20,
              ),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _buildGlassCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon (Dynamic and Animated)
              _buildAnimatedItem(
                index: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getRatingColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      _getRatingIcon(),
                      key: ValueKey<double>(_rating),
                      size: 48,
                      color: _getRatingColor(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Dynamic Subtitle
              _buildAnimatedItem(
                index: 1,
                child: Column(
                  children: [
                    Text(
                      "Rate Experience",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _ratingLabels[_rating.ceil()] ??
                            "We value your opinion",
                        key: ValueKey<double>(_rating),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Rating Bar
              _buildAnimatedItem(
                index: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 42,
                    unratedColor: Colors.grey[300],
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, index) {
                      // Dynamic star color logic
                      return Icon(
                        Icons.star_rounded,
                        color: _rating <= 2 ? Colors.redAccent : Colors.amber,
                      );
                    },
                    onRatingUpdate: (rating) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Text Field with Character Count
              _buildAnimatedItem(
                index: 3,
                child: TextFormField(
                  controller: _feedbackController,
                  maxLines: 4,
                  maxLength: 500, // Added character limit
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Share your thoughts',
                    alignLabelWithHint: true,
                    hintText: "What did you like? What can we improve?",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: Colors.grey[500],
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.all(18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Submit Button
              _buildAnimatedItem(
                index: 4,
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: _primaryColor.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Submit Feedback",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    final double startTime = index * 0.1;
    final double endTime = startTime + 0.4;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, endTime, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(startTime, endTime, curve: Curves.easeOutCubic),
              ),
            ),
        child: child,
      ),
    );
  }

  Widget _buildBackgroundShape(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// --- ANIMATED BACKGROUND ---
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground> {
  Alignment _topAlignment = Alignment.topLeft;
  Alignment _bottomAlignment = Alignment.bottomRight;
  final Color _color1 = const Color(0xFF4A00E0);
  final Color _color2 = const Color(0xFF8E2DE2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAnimation());
  }

  void _startAnimation() {
    if (!mounted) return;
    setState(() {
      _topAlignment = _topAlignment == Alignment.topLeft
          ? Alignment.bottomLeft
          : Alignment.topLeft;
      _bottomAlignment = _bottomAlignment == Alignment.bottomRight
          ? Alignment.topRight
          : Alignment.bottomRight;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 4),
      curve: Curves.easeInOut,
      onEnd: _startAnimation,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_color1, _color2],
          begin: _topAlignment,
          end: _bottomAlignment,
          stops: const [0.2, 0.8],
        ),
      ),
    );
  }
}
