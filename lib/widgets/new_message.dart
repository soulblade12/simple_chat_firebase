//new_message
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() {
    return _NewMessageState();
  }
}

class _NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();
  File? _pickedImageFile;
  // final void Function(File pickedImage) onPickImage;
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitImage() async{

    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 2000,
    );

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _pickedImageFile = File(pickedImage.path);
    });

    await _uploadImageToFirebase();
  }

  Future<void> _uploadImageToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final imageFileName = '${user.uid}_${DateTime.now()}.jpg';
      final reference = FirebaseStorage.instance
          .ref()
          .child('images_chat')
          .child(imageFileName);

      await reference.putFile(_pickedImageFile!);
      final imageUrl = await reference.getDownloadURL();

      final userDocument = await FirebaseFirestore.instance.collection('users')
          .doc(user.uid)
          .get();

      await FirebaseFirestore.instance.collection('chat').add({
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'userId': user.uid,
        'username': userDocument['username'],
        'userImage': userDocument['image_url'],
      });
    } catch (error) {
      print('Error uploading image: $error');
    }
  }

  void _submitMessage() async {
    final enteredMessage = _messageController.text;

    if (enteredMessage.trim().isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    _messageController.clear();

    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    FirebaseFirestore.instance.collection('chat').add({
      'text': enteredMessage,
      'createdAt': Timestamp.now(),
      'userId': user.uid,
      'username': userData.data()!['username'],
      'userImage': userData.data()!['image_url'],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              decoration: const InputDecoration(labelText: 'Send a message...'),
            ),
          ),
          IconButton(
            color: Theme.of(context).colorScheme.primary,
            icon: const Icon(
              Icons.send,
            ),
            onPressed: _submitMessage,
          ),
          IconButton(
            color: Theme.of(context).colorScheme.primary,
            icon: const Icon(
              Icons.camera_alt,
            ),
            onPressed: _submitImage,
          )
        ],
      ),
    );
  }
}