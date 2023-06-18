import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart'; 
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Masuk berhasil, navigasi ke halaman beranda
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
      print('Masuk berhasil: ${userCredential.user?.email}');
    } on FirebaseAuthException catch (e) {
      // Terjadi kesalahan saat masuk, tangani kesalahan di sini
      print('Terjadi kesalahan saat masuk: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: 
        const EdgeInsets.all(16.0),
        children:[
          Align(
             alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 60.0), // Atur jarak ke atas sesuai kebutuhan
              child: Image.asset('assets/Logo.png'),
            ),
          ),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(60.0))),
            ),
            SizedBox(height: 16,),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(60.0))),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
            
            onPressed: _login,
            child: Text('Login'),
          ),
        ] 
      ),
    );
  }
}
