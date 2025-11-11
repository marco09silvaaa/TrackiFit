import 'package:flutter/cupertino.dart';
import 'pages/root_shell.dart';

void main() => runApp(const TrackiFitApp());

class TrackiFitApp extends StatelessWidget {
  const TrackiFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'TrackiFit',
      home: RootShell(),
    );
  }
}
