import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import this for setting orientation
import 'package:flutter_joystick/flutter_joystick.dart';

void main() {
  // Lock the orientation to landscape mode
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
      home: Scaffold(
        appBar: AppBar(title: Text('AI FAN Controller')),
        body: Center(child: ControllerView()),
      ),
    );
  }
}

class ControllerView extends StatefulWidget {
  @override
  _ControllerViewState createState() => _ControllerViewState();
}

class _ControllerViewState extends State<ControllerView> {
  double rotationAngle = 0.0;

  void onJoystickMove(Offset offset) {
    setState(() {
      // Adjust calculations based on the actual joystick input logic
      rotationAngle =
          offset.direction * 180 / 3.1416; // Convert radians to degrees
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if the screen is in landscape mode
        bool isLandscape = constraints.maxWidth > constraints.maxHeight;

        return isLandscape
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DirectionalController(),
                  RotationJoystick(
                    rotationAngle: rotationAngle,
                    onMove: onJoystickMove,
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
                ],
              );
      },
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
    // Handle continuous direction logic here
    print('Direction: $direction');
  }

  void _startContinuousPress(String direction) {
    // Trigger the direction action immediately
    onDirectionPressed(direction);
    // Start a timer to repeat the action
    _holdTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      onDirectionPressed(direction);
    });
  }

  void _stopContinuousPress() {
    // Cancel the timer when the button is released
    if (_holdTimer != null) {
      _holdTimer!.cancel();
      _holdTimer = null;
    }
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

// TODO: 좌우에 따라서 이동 방향이 달라지도록 수정
// TODO: Auto Mode Button 추가
// Joystick-based rotation controller
class RotationJoystick extends StatelessWidget {
  final double rotationAngle;
  final Function(Offset) onMove;

  RotationJoystick({required this.rotationAngle, required this.onMove});

  @override
  Widget build(BuildContext context) {
    return Joystick(
      includeInitialAnimation: false,
      //base: JoystickSquareBase(
      //  decoration: JoystickBaseDecoration(
      //    color: Colors.orange,
      //  ),
      //  //arrowsDecoration: JoystickArrowsDecoration(
      //  //  color: Colors.grey,
      //  //  enableAnimation: false,
      //  //),
      //),
      base: Container(
        width: 200,
        height: 50,
        decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(20))),
      ),
      stick: JoystickStick(
        size: 40,
        decoration: JoystickStickDecoration(
          color: Colors.grey,
          shadowColor: Colors.white.withOpacity(0.5),
        ),
      ),
      listener: (details) {
        //onMove(details.offset); // Update rotation angle based on joystick movement
      },
    );
  }
}
