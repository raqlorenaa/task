import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_controller.dart';
import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';

import 'home_page.dart';
import 'theme_controller.dart'; // ✅ importa seu ThemeController

final ThemeData lightTheme = ThemeData.light().copyWith(
  primaryColor: Colors.indigo,
  appBarTheme: const AppBarTheme(backgroundColor: Colors.indigo),
);

final ThemeData darkTheme = ThemeData.dark().copyWith(
  primaryColor: Colors.amber,
  appBarTheme: const AppBarTheme(backgroundColor: Colors.black87),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GetStorage.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Task App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeController().theme, // Usa o modo salvo
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController());
        Get.put(ThemeController()); // Ativa controller do tema
      }),
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/home', page: () => const HomePage()),
      ],
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
