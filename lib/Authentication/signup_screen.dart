import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as fStorage;
import 'package:path/path.dart' as Path;

import '../global/global.dart';
import '../home_screen.dart';
import '../widgets/error_dialog.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/reuseable_widget.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {




  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _userNameTextController = TextEditingController();
  TextEditingController _locationTextController = TextEditingController();

  XFile? imageXFile;
  final ImagePicker _picker = ImagePicker();



  String imageUrl = "";
  String completeAddress ="";

  Future<void> _getImage() async {
    imageXFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      imageXFile;
    });
  }



  Future<void> formValidation() async {
    if (imageXFile == null) {
      showDialog(
          context: context,
          builder: (c) {
            return const ErrorDialog(
              message: "Please select an image",
            );
          });
    } else {
      if (_passwordTextController.text.isNotEmpty &&
          _emailTextController.text.isNotEmpty &&
          _userNameTextController.text.isNotEmpty) {
        showDialog(
          context: context,
          builder: (c){
            {
              return const LoadingDialog(
                message: "Registering Account",
              );
            }
          });

        String fileName  = DateTime.now().microsecondsSinceEpoch.toString();
        fStorage.Reference reference = fStorage.FirebaseStorage.instance.ref().child('users').child(fileName);
        fStorage.UploadTask uploadTask = reference.putFile(File(imageXFile!.path));
        fStorage.TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
        await taskSnapshot.ref.getDownloadURL().then((url) {
          imageUrl = url;
          authenticateSellerAndSignUp();

        });



      } else {
        showDialog(
            context: context,
            builder: (c) {
              return const ErrorDialog(
                message: "Please write complete required full info",
              );
            });
      }
    }
  }



  void authenticateSellerAndSignUp() async
  {
    User? currentUser;

    await firebaseUser.createUserWithEmailAndPassword(
      email: _emailTextController.text.trim(),
      password: _passwordTextController.text.trim(),
    ).then((auth) {
      currentUser = auth.user;
    }).catchError((error){
      Navigator.pop(context);
      showDialog(
          context: context,
          builder: (c)
          {
            return ErrorDialog(
              message: error.message.toString(),
            );
          }
      );
    });

    if(currentUser != null)
    {
      saveDataToFirestore(currentUser!).then((value) {
        Navigator.pop(context);
        //send user to homePage
        Route newRoute = MaterialPageRoute(builder: (c) => HomeScreen());
        Navigator.pushReplacement(context, newRoute);
      });
    }
  }

  Future saveDataToFirestore(User currentUser) async {
    FirebaseFirestore.instance.collection("users").doc(currentUser.uid).set(
        {
          "UID": currentUser.uid,
          "Email": currentUser.email,
          "Name": _userNameTextController.text.trim(),

          "address": completeAddress,
          "status": "approved",
          "earnings": 0.0,

        });

    //save data locally
    sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences!.setString("uid", currentUser.uid);
    await sharedPreferences!.setString("email", currentUser.email.toString());
    await sharedPreferences!.setString("name", _userNameTextController.text.trim());


  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: MediaQuery
            .of(context)
            .size
            .width,
        height: MediaQuery
            .of(context)
            .size
            .height,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery
              .of(context)
              .size
              .height * 0.12, 20, 0),
          child: Column(
            children: <Widget>[
              InkWell(
                onTap: () {
                  _getImage();
                },
                child: CircleAvatar(
                  radius: MediaQuery
                      .of(context)
                      .size
                      .width * 0.20,
                  backgroundColor: Colors.black12,
                  backgroundImage: imageXFile == null
                      ? null
                      : FileImage(File(imageXFile!.path)),
                  child: imageXFile == null
                      ? Icon(
                    Icons.add_photo_alternate,
                    size: MediaQuery
                        .of(context)
                        .size
                        .width * 0.20,
                    color: Colors.grey,
                  )
                      : null,
                ),
              ),
              SizedBox(height: 30),
              reuseableTextField('User Name', Icons.person_outline, false, true,
                  _userNameTextController),
              SizedBox(height: 20),
              reuseableTextField(
                  'E-Mail', Icons.mail, false, true, _emailTextController),
              SizedBox(height: 20),
              reuseableTextField(
                  'Password', Icons.key, true, true, _passwordTextController),

              SizedBox(height: 40),
              signInSignOutButton(context, false, () {
                formValidation();
                


                // FirebaseAuth.instance
                //     .createUserWithEmailAndPassword(
                //     email: _emailTextController.text,
                //     password: _passwordTextController.text)
                //     .then((value) {
                //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                //     content: Text('Created New Account'),
                //   ));
                //   print("Created New Account");
                //
                //   Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //           builder: (context) => const HomeScreen()));
                // }).onError((error, stackTrace) {
                //   print("Error ${error.toString()}");
                //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                //     content: Text('Error ${error.toString()}'),
                //   ));
                // }
              //  );


              }),
            ],
          ),
        ),
      ),
    );
  }
}
