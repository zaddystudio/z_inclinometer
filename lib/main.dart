import 'dart:async';
import 'dart:ui'; // Required for blur effects
import 'package:flutter/cupertino.dart'; // iOS Widgets
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ZInclinometerApp());
}

class ZInclinometerApp extends StatelessWidget {
  const ZInclinometerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Z Inclinometer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(
          0xFF000000,
        ), // Pure Black (Apple Style)
        useMaterial3: true,
        fontFamily: 'System',
      ),
      home: const LevelScreen(),
    );
  }
}

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  double _x = 0;
  double _y = 0;
  bool _isFrozen = false;
  StreamSubscription<AccelerometerEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  void _initSensors() {
    _subscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        if (!_isFrozen) {
          setState(() {
            double alpha = 0.1;
            _x = _x * (1 - alpha) + event.x * alpha;
            _y = _y * (1 - alpha) + event.y * alpha;
          });
        }
      },
      onError: (e) => debugPrint("Sensor Error: $e"),
      cancelOnError: false,
    );
  }

  void _toggleFreeze() {
    setState(() {
      _isFrozen = !_isFrozen;
      if (_isFrozen) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    });
  }

  // --- iOS Style Help Dialog ---
  void _showTiltHelp(String axis) {
    String title = "";
    String description = "";
    String usage = "";

    // LOGIC FIX: This now correctly looks for "X" because we renamed labels back to "X TILT"
    if (axis.contains("X")) {
      title = "X TILT (Roll)";
      description =
          "Side-to-Side Movement\n\nImagine putting your phone on a table and lifting just the left edge or the right edge. That is X.";
      usage = "Checking if a picture frame is straight on a wall.";
    } else {
      title = "Y TILT (Pitch)";
      description =
          "Forward & Backward Movement\n\nImagine lifting the top (camera) or the bottom (charging port) of the phone. That is Y.";
      usage = "Checking if a table or shelf is sloping downwards or upwards.";
    }

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Column(
          children: [
            const SizedBox(height: 10),
            Text(description, textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Text(
              "BEST USED FOR:",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 5),
            Text(usage, style: const TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 15),
            const Text(
              "💡 Tip: To level a flat surface (table), BOTH X and Y must be 0°.",
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Got it",
              style: TextStyle(color: CupertinoColors.activeBlue),
            ),
          ),
        ],
      ),
    );
  }

  // --- iOS Style About Dialog ---
  void _showAboutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.info,
                color: CupertinoColors.systemCyan,
                size: 40,
              ),
              const SizedBox(height: 15),
              Text(
                "COOKED BY",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Zaddy Digital Solutions",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                width: 40,
                height: 1,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 15),
              const Text(
                "hi@zaddyhost.top",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 5),
              const Text(
                "+234 706 063 3216",
                style: TextStyle(color: Colors.grey),
              ),

              // --- MOVE THESE TWO INSIDE THE COLUMN CHILDREN ---
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CupertinoColors.systemCyan.withOpacity(0.1),
                  foregroundColor: CupertinoColors.systemCyan,
                  side: const BorderSide(
                    color: CupertinoColors.systemCyan,
                    width: 0.5,
                  ),
                ),
                onPressed: () =>
                    launchUrl(Uri.parse("https://zaddyhost.top/creatives")),
                child: const Text("GET MORE APPS"),
              ),
              // ------------------------------------------------
            ],
          ), // This bracket now correctly closes the content: Column

          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close",
                style: TextStyle(color: CupertinoColors.activeBlue),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double xDegrees = _x * 9.0;
    double yDegrees = _y * 9.0;
    bool isLevel = xDegrees.abs() < 1.5 && yDegrees.abs() < 1.5;

    Color activeColor = isLevel
        ? const Color(0xFF32D74B)
        : const Color(0xFFFF453A);
    Color bubbleColor = _isFrozen
        ? Colors.grey
        : (isLevel ? const Color(0xFF32D74B) : const Color(0xFFFFD60A));
    Color borderColor = _isFrozen
        ? CupertinoColors.activeOrange
        : Colors.white12;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Z INCLINOMETER',
          style: TextStyle(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isFrozen)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Icon(
                CupertinoIcons.lock_fill,
                color: CupertinoColors.activeOrange,
                size: 20,
              ),
            ),
          IconButton(
            icon: const Icon(
              CupertinoIcons.info_circle,
              color: CupertinoColors.systemCyan,
            ),
            onPressed: _showAboutDialog,
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: GestureDetector(
        onTap: _toggleFreeze,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size.infinite, painter: GridPainter()),

            if (_isFrozen)
              Positioned(
                top: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeOrange.withValues(
                          alpha: 0.2,
                        ),
                        border: Border.all(
                          color: CupertinoColors.activeOrange.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "HOLD ACTIVE",
                        style: TextStyle(
                          color: CupertinoColors.activeOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // --- MAIN HOUSING ---
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Embossed Housing Gradient
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF292929), Color(0xFF000000)],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black,
                      offset: Offset(10, 10),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.05),
                      offset: const Offset(-5, -5),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: isLevel
                          ? const Color(0xFF32D74B).withValues(alpha: 0.15)
                          : Colors.transparent,
                      blurRadius: 60,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Inner "Floor" Gradient
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF1C1C1E),
                            const Color(0xFF000000).withValues(alpha: 0.8),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),

                    // --- CROSSHAIR LINES (Restored) ---
                    Container(
                      width: 1,
                      height: 300,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    Container(
                      width: 300,
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    Container(
                      width: 20,
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),

                    // --- EMBOSSED Z CENTER ---
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF3A3A3C),
                            const Color(0xFF1C1C1E),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 5,
                            offset: const Offset(3, 3),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 5,
                            offset: const Offset(-2, -2),
                          ),
                        ],
                        border: Border.all(
                          color: activeColor.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Z",
                          style: TextStyle(
                            color: activeColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 32,
                            shadows: [
                              Shadow(
                                color: activeColor.withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- 3D MOVING SPHERE (Reduced Shadow) ---
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 60),
                      alignment: Alignment(
                        (_x / 5).clamp(-1.0, 1.0) * -1,
                        (_y / 5).clamp(-1.0, 1.0),
                      ),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.9),
                              bubbleColor,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                            center: const Alignment(-0.4, -0.4),
                            focal: const Alignment(-0.4, -0.4),
                            focalRadius: 0.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: bubbleColor.withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.3,
                              ), // Reduced shadow intensity
                              blurRadius: 4, // Tighter blur
                              offset: const Offset(2, 2), // Closer to ball
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                width: 12,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  borderRadius: const BorderRadius.all(
                                    Radius.elliptical(12, 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- BOTTOM READOUT AREA (Glassy) ---
            Positioned(
              bottom: 50,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 25,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2C2C2E).withValues(alpha: 0.6),
                          const Color(0xFF1C1C1E).withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // FIX: Changed Labels back to "X TILT" and "Y TILT" to fix the help dialog bug
                        _buildReadout("X TILT", xDegrees),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.white12,
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                        ),
                        _buildReadout("Y TILT", yDegrees),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadout(String label, double value) {
    Color textColor = _isFrozen
        ? CupertinoColors.activeOrange
        : (value.abs() < 1.5 ? const Color(0xFF32D74B) : Colors.white);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showTiltHelp(label),
              child: const Icon(
                CupertinoIcons.question_circle,
                color: CupertinoColors.systemCyan,
                size: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "${value.toStringAsFixed(1)}°",
          style: TextStyle(
            color: textColor,
            fontSize: 32,
            fontWeight: FontWeight.w300,
            fontFamily: 'System',
            shadows: [
              Shadow(color: textColor.withValues(alpha: 0.3), blurRadius: 10),
            ],
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    double step = 50;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
