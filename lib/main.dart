import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'registerUser.dart';
import 'userhome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(), // Halaman utama
        '/login': (context) => LoginPage(),
        // ...
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 100.0), // Atur jarak ke atas sesuai kebutuhan
              child: Image.asset('assets/Logo.png'),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Pilih Role Anda', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.blue[300]),),
                SizedBox(height: 16,),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(100, 50)
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                  },
                  child: Text('Admin', style: TextStyle(fontSize: 15.0),),
                ),
                SizedBox(height: 5,),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(100, 50)
                  ),
                  onPressed: () {

                    Navigator.push(context, MaterialPageRoute(builder: (context) => UserLoginPage()));
                  },
                  child: Text('Pembeli', style: TextStyle(fontSize: 15.0),),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class UserLoginPage extends StatefulWidget {
  @override
  _UserLoginPageState createState() => _UserLoginPageState();
}

class _UserLoginPageState extends State<UserLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    final String email = _emailController.text;
    final String password = _passwordController.text;

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Login berhasil, lakukan navigasi ke halaman selanjutnya (misalnya home)
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomePageUser()));
      } else {
        // Login gagal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Align(
             alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 60.0), // Atur jarak ke atas sesuai kebutuhan
              child: Image.asset('assets/Logo.png'),
            ),
          ),
          TextFormField(
            controller: _emailController,
            decoration:
            InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0))),
          ),
          SizedBox(height: 16.0),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password',  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0))),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _login,
            child: Text('Login'),
          ),
          SizedBox(height: 16.0),
          TextButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => RegisterPage()));
            },
            child: Text('Register'),
          ),
        ],
      ),
    );
  }
}
