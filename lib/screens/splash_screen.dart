import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../widgets/common.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: DropzyColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropzyIconTile(size: 84),
            SizedBox(height: 20),
            Text('Dropzy',
                style: TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w800, color: DropzyColors.ink)),
            SizedBox(height: 6),
            Text(AppConfig.tagline, style: TextStyle(color: DropzyColors.inkSoft)),
            SizedBox(height: 36),
            CircularProgressIndicator(color: DropzyColors.primary),
          ],
        ),
      ),
    );
  }
}
