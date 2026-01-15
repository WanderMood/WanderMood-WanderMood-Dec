import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/profile/presentation/widgets/threejs_globe_widget.dart';

class GlobeScreen extends StatelessWidget {
  const GlobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Your Travel Globe',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: const ThreeJsGlobeWidget(
        autoRotate: true,
      ),
    );
  }
}
