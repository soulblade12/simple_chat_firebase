//auth.dart
import 'dart:io';
import 'package:firebase_app/providers/authstate.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

Future<void> _signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();

    if (googleSignInAccount == null) {
      // The user canceled the sign-in process
      return;
    }

    final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential authResult = await _firebase.signInWithCredential(credential);
    final User? user = authResult.user;

    if (user != null) {
      // Handle successful Google Sign-In
      // You can add your logic here, e.g., navigate to the home screen
    }
  } catch (error) {
    print('Error during Google Sign-In: $error');
  }
}


final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  // var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredUsername = '';
  File? _selectedImage;
  var _isAuthenticating = false;

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid || !Provider.of<AuthChangeState>(context, listen: false).isLogin && _selectedImage == null) {
      // show error message ...
      return;
    }

    _form.currentState!.save();

    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (Provider.of<AuthChangeState>(context, listen: false).isLogin) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        // ...
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Authentication failed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              ChangeNotifierProvider(
                create: (context) => AuthChangeState(),  // Provide AuthProvider
                child: Consumer<AuthChangeState>(
                  builder: (context, AuthChangeState, _) {
                    return Card(
                      margin: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _form,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!AuthChangeState.isLogin)
                                  UserImagePicker(
                                    onPickImage: (pickedImage) {
                                      _selectedImage = pickedImage;
                                    },
                                  ),
                                TextFormField(
                                  decoration: const InputDecoration(
                                      labelText: 'Email Address'),
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  textCapitalization: TextCapitalization.none,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty ||
                                        !value.contains('@')) {
                                      return 'Please enter a valid email address.';
                                    }

                                    return null;
                                  },
                                  onSaved: (value) {
                                    _enteredEmail = value!;
                                  },
                                ),
                                if (!AuthChangeState.isLogin)
                                  TextFormField(
                                    decoration:
                                    const InputDecoration(labelText: 'Username'),
                                    enableSuggestions: false,
                                    validator: (value) {
                                      if (value == null ||
                                          value.isEmpty ||
                                          value.trim().length < 4) {
                                        return 'Please enter at least 4 characters.';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _enteredUsername = value!;
                                    },
                                  ),
                                TextFormField(
                                  decoration:
                                  const InputDecoration(labelText: 'Password'),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.trim().length < 6) {
                                      return 'Password must be at least 6 characters long.';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _enteredPassword = value!;
                                  },
                                ),
                                const SizedBox(height: 12),
                                if (_isAuthenticating)
                                  const CircularProgressIndicator(),
                                if (!_isAuthenticating)
                                  ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                    ),
                                    child: Text(AuthChangeState.isLogin ? 'Login' : 'Signup'),
                                  ),
                                if (!_isAuthenticating)
                                  TextButton(
                                    onPressed: () {
                                      AuthChangeState.clickAuth();
                                    },
                                    child: Text(AuthChangeState.isLogin
                                        ? 'Create an account'
                                        : 'I already have an account'),
                                  ),
                                if (!_isAuthenticating)
                                  ElevatedButton.icon(
                                    onPressed: _signInWithGoogle,
                                    icon: Icon(Icons.g_mobiledata), // You can replace this with a Google logo
                                    label: Text('Sign In with Google'),
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.white, // Use the Google color or customize
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}