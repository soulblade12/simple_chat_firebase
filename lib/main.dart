//main.dart
import 'package:firebase_app/providers/authstate.dart';
import 'package:firebase_app/screens/auth.dart';
import 'package:firebase_app/screens/chat.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers:
    [
      ChangeNotifierProvider(
        create: (context) => AuthChangeState(),
      ),
    ]
      ,child: MaterialApp(
      title: 'FlutterChat',
      theme: ThemeData().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 63, 17, 177)),
      ),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(),
          builder: (ctx , snapshot){
            if(snapshot.hasData){
              return const ChatScreen();
            }
            return const AuthScreen();
          }),
    ),
    );
  }
}