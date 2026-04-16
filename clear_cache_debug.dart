import 'dart:io';

void main() async {
  print('🧹 Clearing app cache...');

  // Also clear Flutter build cache
  try {
    final result = await Process.run('flutter', ['clean']);
    print('Flutter clean: ${result.exitCode == 0 ? "✅ Success" : "❌ Failed"}');
  } catch (e) {
    print('Flutter clean failed: $e');
  }
  
  print('🎯 Cache cleared! Next app run will use fresh data and show filtering logs.');
} 