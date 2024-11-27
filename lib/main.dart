// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'mqtt_service.dart'; // MQTTService 임포트
import 'dart:io' show Platform;

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
      title: 'AI FAN Controller',
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

  late MQTTService mqttService;

  @override
  void initState() {
    super.initState();
    // MQTTService 초기화 (사용자명 및 비밀번호 포함)
    mqttService = MQTTService(
      broker: getBrokerAddress(),
      port: 1883, // 기본 MQTT 포트
      clientIdentifier:
          'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
      username: 'AIFAN', // 설정한 사용자명
      password: 'AIFAN', // 설정한 비밀번호
      useTLS: false, // TLS 사용 여부
    );

    mqttService.connect();

    // 수신 메시지 리스닝 (필요 시 사용)
    mqttService.messages.listen((message) {
      // 수신된 메시지 처리
      print('ControllerView: Received message: $message');
      // 예: UI 업데이트
    });
  }

  @override
  void dispose() {
    mqttService.dispose();
    super.dispose();
  }

  String getBrokerAddress() {
    if (Platform.isAndroid) {
      return '10.0.2.2'; // Android 에뮬레이터용
    } else if (Platform.isIOS) {
      return 'localhost'; // iOS 시뮬레이터용
    } else {
      // 실제 기기 또는 다른 플랫폼용
      // 실제 기기에서는 호스트 머신의 로컬 IP 주소를 사용하세요 (예: '192.168.1.100')
      return '192.168.1.100'; // 예시 IP 주소
    }
  }

  void onJoystickMove(Offset offset) {
    setState(() {
      rotationAngle = offset.direction * 180 / 3.1416; // 라디안을 도로 변환
    });

    // MQTT로 회전 각도 전송
    mqttService.publishMessage(
        'fan/control/rotation', rotationAngle.toString());
  }

  void toggleAutoMode() {
    setState(() {
      isAutoMode = !isAutoMode;
    });

    // MQTT로 Auto Mode 상태 전송
    String message = isAutoMode ? 'enable_autonomous' : 'disable_autonomous';
    mqttService.publishMessage('fan/control/auto_mode', message);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 메인 컨텐츠를 포함하는 Scaffold
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
                            DirectionalController(
                              onDirectionPressed: (direction) {
                                // 방향 메시지 MQTT로 전송
                                mqttService.publishMessage(
                                    'fan/control/direction', direction);
                              },
                            ),
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
                        DirectionalController(
                          onDirectionPressed: (direction) {
                            // 방향 메시지 MQTT로 전송
                            mqttService.publishMessage(
                                'fan/control/direction', direction);
                          },
                        ),
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
        // Auto Mode 활성화 시 전체 화면 오버레이
        if (isAutoMode)
          Positioned.fill(
            child: GestureDetector(
              onTap: toggleAutoMode,
              child: Container(
                color: Colors.grey.withOpacity(0.7),
                child: Center(
                  child: Text(
                    'Autonomous Mode Active',
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

// AutoModeButton 컴포넌트
class AutoModeButton extends StatelessWidget {
  final bool isAutoMode;
  final VoidCallback onPressed;

  AutoModeButton({required this.isAutoMode, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(isAutoMode ? 'Auto Mode OFF' : 'Auto Mode ON'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        textStyle: TextStyle(fontSize: 18),
      ),
    );
  }
}

// DirectionalController 컴포넌트
class DirectionalController extends StatefulWidget {
  final Function(String) onDirectionPressed;

  DirectionalController({required this.onDirectionPressed});

  @override
  _DirectionalControllerState createState() => _DirectionalControllerState();
}

class _DirectionalControllerState extends State<DirectionalController> {
  Timer? _holdTimer;

  void onDirectionPressed(String direction) {
    print('DirectionalController: Direction pressed: $direction');
    widget.onDirectionPressed(direction);
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
              child: Icon(Icons.arrow_upward, size: 40, color: Colors.black),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTapDown: (_) => _startContinuousPress("down"),
              onTapUp: (_) => _stopContinuousPress(),
              onTapCancel: _stopContinuousPress,
              child: Icon(Icons.arrow_downward, size: 40, color: Colors.black),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTapDown: (_) => _startContinuousPress("left"),
              onTapUp: (_) => _stopContinuousPress(),
              onTapCancel: _stopContinuousPress,
              child: Icon(Icons.arrow_back, size: 40, color: Colors.black),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTapDown: (_) => _startContinuousPress("right"),
              onTapUp: (_) => _stopContinuousPress(),
              onTapCancel: _stopContinuousPress,
              child: Icon(Icons.arrow_forward, size: 40, color: Colors.black),
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

// RotationJoystick 컴포넌트
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
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
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
