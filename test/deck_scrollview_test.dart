import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deck_scrollview/deck_scroll_view.dart';

void main() {
  const MethodChannel channel = MethodChannel('deck_scrollview');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

}
