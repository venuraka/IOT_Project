

import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
        ),
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: isMobile ? buildMobileLayout(context) : buildWebLayout(context),
    );
  }

  Widget buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Full image, no fixed height
          
          Image.asset(
            'images/login2.png',
            width: double.infinity,
            fit: BoxFit.contain,
          ),

          // White container with spacing
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Please Enter your Details',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 35),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(hintText: 'Enter Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Please enter your email' : null,
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(hintText: 'Enter Password'),
                        obscureText: true,
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Please enter your password' : null,
                      ),
                      SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            padding: EdgeInsets.symmetric(vertical: 15),
                            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              print('Email: ${emailController.text}');
                              print('Password: ${passwordController.text}');
                            }
                          },
                          child: Text('Sign In', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWebLayout(BuildContext context) {
    return Row(
      children: [
        // Left side - Login Form
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please Enter your Details',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(hintText: 'Enter Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                (value == null || value.isEmpty) ? 'Please enter your email' : null,
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: passwordController,
                            decoration: InputDecoration(hintText: 'Enter Password'),
                            obscureText: true,
                            validator: (value) =>
                                (value == null || value.isEmpty) ? 'Please enter your password' : null,
                          ),
                          SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[900],
                                padding: EdgeInsets.symmetric(vertical: 15),
                                textStyle:
                                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  print('Email: ${emailController.text}');
                                  print('Password: ${passwordController.text}');
                                }
                              },
                              child: Text('Sign In', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right side - Image
        Expanded(
          flex: 1,
          child: Image.asset(
            'images/login2.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}
