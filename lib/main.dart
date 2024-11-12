import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ControllerView(),
    );
  }
}

class ControllerView extends StatefulWidget {
  @override
  _ControllerViewState createState() => _ControllerViewState();
}

class _ControllerViewState extends State<ControllerView> {
  double rotationAngle = 0.0;
  bool isAutoMode = false;

  void onJoystickMove(Offset offset) {
    setState(() {
      rotationAngle =
          offset.direction * 180 / 3.1416; // Convert radians to degrees
    });
  }

  void toggleAutoMode() {
    setState(() {
      isAutoMode = !isAutoMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scaffold with the main content
        Scaffold(
          appBar: AppBar(title: Text('AI FAN Controller')),
          body: LayoutBuilder(
            builder: (context, constraints) {
              bool isLandscape = constraints.maxWidth > constraints.maxHeight;
              return isLandscape
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            DirectionalController(),
                            RotationJoystick(
                              rotationAngle: rotationAngle,
                              onMove: onJoystickMove,
                            ),
                          ],
                        ),
                        AutoModeButton(
                          isAutoMode: isAutoMode,
                          onPressed: toggleAutoMode,
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DirectionalController(),
                        SizedBox(height: 100),
                        RotationJoystick(
                          rotationAngle: rotationAngle,
                          onMove: onJoystickMove,
                        ),
                        AutoModeButton(
                          isAutoMode: isAutoMode,
                          onPressed: toggleAutoMode,
                        ),
                      ],
                    );
            },
          ),
        ),
        // Full-screen overlay when isAutoMode is true
        if (isAutoMode)
          Positioned.fill(
            child: GestureDetector(
              onTap: toggleAutoMode,
              child: Container(
                color: Colors.grey.withOpacity(0.7),
                child: Center(
                  child: Text(
                    '자율주행 실행 중입니다.',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// AutoModeButton component
class AutoModeButton extends StatelessWidget {
  final bool isAutoMode;
  final VoidCallback onPressed;

  AutoModeButton({required this.isAutoMode, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(isAutoMode ? 'Auto Mode OFF' : 'Auto Mode ON'),
    );
  }
}

class DirectionalController extends StatefulWidget {
  @override
  _DirectionalControllerState createState() => _DirectionalControllerState();
}

class _DirectionalControllerState extends State<DirectionalController> {
  Timer? _holdTimer;

  void onDirectionPressed(String direction) {
    print('Direction: $direction');
  }

  void _startContinuousPress(String direction) {
    onDirectionPressed(direction);
    _holdTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      onDirectionPressed(direction);
    });
  }

  void _stopContinuousPress() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.blue[100],
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTapDown: (_) => _startContinuousPress("up"),
              onTapUp: (_) => _stopContinuousPress(),
              onTapCancel: _stopContinuousPress,
              child: Icon(Icons.arrow_upward),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTapDown: (_) => _startContinuousPress("down"),
              onTapUp: (_) => _stopContinuousPress(),
              onTapCancel: _stopContinuousPress,
              child: Icon(Icons.arrow_downward),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTapDown: (_) => _startContinuousPress("left"),
              onTapUp: (_) => _stopContinuousPress(),
              onTapCancel: _stopContinuousPress,
              child: Icon(Icons.arrow_back),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTapDown: (_) => _startContinuousPress("right"),
              onTapUp: (_) => _stopContinuousPress(),
              onTapCancel: _stopContinuousPress,
              child: Icon(Icons.arrow_forward),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopContinuousPress();
    super.dispose();
  }
}

class RotationJoystick extends StatelessWidget {
  final double rotationAngle;
  final Function(Offset) onMove;

  RotationJoystick({required this.rotationAngle, required this.onMove});

  @override
  Widget build(BuildContext context) {
    return Joystick(
      includeInitialAnimation: false,
      base: Container(
        width: 200,
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      stick: JoystickStick(
        size: 40,
        decoration: JoystickStickDecoration(
          color: Colors.grey,
          shadowColor: Colors.white.withOpacity(0.5),
        ),
      ),
      listener: (details) {
        //onMove(details.offset);
      },
    );
  }
}
