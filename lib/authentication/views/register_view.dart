import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/authentication/views/login_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _sellerNameController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();

  // Function to save user data
  Future<void> saveUserData(User user, String name, String phoneNumber, String storeName) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'email': user.email,
        'phone_number': phoneNumber,
        'profileImageUrl':
            "https://firebasestorage.googleapis.com/v0/b/unshelf-d4567.appspot.com/o/user_avatars%2FDvVHPPSWMtV7GBFjSW1jymsv1op1.png?alt=media&token=084a7a1a-f962-4348-9bb7-7d1ef3476856",
        'type': 'buyer',
        'isBanned': false,
        'points': 0,
      });

      // await FirebaseFirestore.instance.collection('stores').doc(user.uid).set({
      //   'store_name': storeName,
      //   'store_schedule': {
      //     'Monday': {'open': 'Closed', 'close': 'Closed'},
      //     'Tuesday': {'open': 'Closed', 'close': 'Closed'},
      //     'Wednesday': {'open': 'Closed', 'close': 'Closed'},
      //     'Thursday': {'open': 'Closed', 'close': 'Closed'},
      //     'Friday': {'open': 'Closed', 'close': 'Closed'},
      //     'Saturday': {'open': 'Closed', 'close': 'Closed'},
      //     'Sunday': {'open': 'Closed', 'close': 'Closed'},
      //   },
      //   'longitude': 0,
      //   'latitude': 0,
      // });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create user data')),
      );
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        User user = userCredential.user!;
        await saveUserData(user, _sellerNameController.text, _phoneNumberController.text, _storeNameController.text);

        // User created successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful')),
        );

        // Go to login page
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginView()));
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          message = 'The account already exists for that email.';
        } else {
          message = 'An error occurred: ${e.message}. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        // Handle other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Image.network(
                'https://firebasestorage.googleapis.com/v0/b/unshelf-d4567.appspot.com/o/Unshelf.png?alt=media&token=ea449292-f36d-4dfe-a90a-2bef5c341694',
                height: 100,
              ),
              TextFormField(
                controller: _sellerNameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  } else if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  } else if (value.length < 11) {
                    return 'Phone number must be at least 11 characters';
                  } else if (value[0] != '0' && value[1] != '9') {
                    return 'Phone number must start with 09';
                  }
                  return null;
                },
              ),
              // TextFormField(
              //   controller: _storeNameController,
              //   decoration: const InputDecoration(labelText: 'Store Name'),
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return 'Please enter your store name';
              //     }
              //     return null;
              //   },
              // ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Sign Up'),
              ),
              const Text("By signing up, you agree to Unshelf's Terms of Use and Privacy Policy"),
              const SizedBox(height: 20),
              const Text('Already have an account?'),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginView()));
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
