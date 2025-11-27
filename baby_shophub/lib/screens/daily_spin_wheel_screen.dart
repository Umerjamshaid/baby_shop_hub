import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DailySpinWheelScreen extends StatefulWidget {
  const DailySpinWheelScreen({super.key});

  @override
  State<DailySpinWheelScreen> createState() => _DailySpinWheelScreenState();
}

class _DailySpinWheelScreenState extends State<DailySpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ConfettiController _confettiController;
  bool _isSpinning = false;
  String? _result;
  bool _canSpin = true;

  final List<SpinReward> _rewards = [
    SpinReward('5% OFF', Colors.orange, '5OFF'),
    SpinReward('Try Again', Colors.grey, null),
    SpinReward('10% OFF', Colors.red, '10OFF'),
    SpinReward('Free Shipping', Colors.blue, 'FREESHIP'),
    SpinReward('15% OFF', Colors.purple, '15OFF'),
    SpinReward('100 Points', Colors.green, 'POINTS100'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _checkIfCanSpin();
  }

  Future<void> _checkIfCanSpin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      setState(() => _canSpin = false);
      return;
    }

    final userId = authProvider.currentUser!.id;
    final doc = await FirebaseFirestore.instance
        .collection('spinHistory')
        .doc(userId)
        .get();

    if (doc.exists) {
      final lastSpin = (doc.data()!['lastSpin'] as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(lastSpin);

      if (difference.inHours < 24) {
        setState(() => _canSpin = false);
      }
    }
  }

  Future<void> _spin() async {
    if (!_canSpin || _isSpinning) return;

    setState(() => _isSpinning = true);

    // Random result
    final random = math.Random();
    final resultIndex = random.nextInt(_rewards.length);
    final rotations = 5 + random.nextDouble() * 3; // 5-8 full rotations
    final finalAngle = (resultIndex / _rewards.length) * 2 * math.pi;

    _controller.reset();
    await _controller.animateTo(
      rotations + (finalAngle / (2 * math.pi)),
      curve: Curves.easeOutCubic,
    );

    final reward = _rewards[resultIndex];
    setState(() {
      _result = reward.label;
      _isSpinning = false;
      _canSpin = false;
    });

    // Save spin to Firestore
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      await FirebaseFirestore.instance
          .collection('spinHistory')
          .doc(authProvider.currentUser!.id)
          .set({
        'lastSpin': FieldValue.serverTimestamp(),
        'lastReward': reward.label,
        'couponCode': reward.couponCode,
      });
    }

    // Show confetti if won something
    if (reward.couponCode != null) {
      _confettiController.play();
      _showRewardDialog(reward);
    }
  }

  void _showRewardDialog(SpinReward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You won: ${reward.label}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (reward.couponCode != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                ),
                child: Text(
                  'Code: ${reward.couponCode}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use this code at checkout!',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Spin & Win'),
        backgroundColor: Colors.orange,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.orange[100]!, Colors.white],
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🎰 Spin the Wheel!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _canSpin
                      ? 'Tap the wheel to spin'
                      : 'Come back tomorrow for another spin!',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 40),

                // Spin Wheel
                GestureDetector(
                  onTap: _spin,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _controller.value * 2 * math.pi,
                        child: child,
                      );
                    },
                    child: CustomPaint(
                      size: const Size(300, 300),
                      painter: SpinWheelPainter(_rewards),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Spin Button
                ElevatedButton(
                  onPressed: _canSpin && !_isSpinning ? _spin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _isSpinning
                        ? 'Spinning...'
                        : _canSpin
                            ? 'SPIN NOW!'
                            : 'Already Spun Today',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                if (_result != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'You got: $_result',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                Colors.orange,
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SpinReward {
  final String label;
  final Color color;
  final String? couponCode;

  SpinReward(this.label, this.color, this.couponCode);
}

class SpinWheelPainter extends CustomPainter {
  final List<SpinReward> rewards;

  SpinWheelPainter(this.rewards);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sectionAngle = 2 * math.pi / rewards.length;

    // Draw sections
    for (int i = 0; i < rewards.length; i++) {
      final paint = Paint()
        ..color = rewards[i].color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sectionAngle - math.pi / 2,
        sectionAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sectionAngle - math.pi / 2,
        sectionAngle,
        true,
        borderPaint,
      );

      // Draw text
      final textPainter = TextPainter(
        text: TextSpan(
          text: rewards[i].label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * sectionAngle + sectionAngle / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -radius * 0.7),
      );
      canvas.restore();
    }

    // Draw center circle
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 30, centerPaint);

    // Draw pointer (triangle at top)
    final pointerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, 20);
    path.lineTo(center.dx - 15, 0);
    path.lineTo(center.dx + 15, 0);
    path.close();
    canvas.drawPath(path, pointerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
