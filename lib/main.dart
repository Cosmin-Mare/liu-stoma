import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:liu_stoma/app.dart';
import 'package:window_manager/window_manager.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait on mobile
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || 
                   defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  // Set minimum window size on desktop and open in near-fullscreen
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
                   defaultTargetPlatform == TargetPlatform.macOS ||
                   defaultTargetPlatform == TargetPlatform.linux)) {
    await windowManager.ensureInitialized();
    
    // Set minimum size to approximately 2/3 of a typical 1920x1080 screen
    const minWidth = 1280.0;  // 2/3 of 1920
    const minHeight = 720.0;  // 2/3 of 1080
    
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(minWidth, minHeight),
      center: true,
      titleBarStyle: TitleBarStyle.normal,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.maximize();
    });
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}
