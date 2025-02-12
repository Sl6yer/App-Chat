import 'package:app_chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:app_chat/chat_message.dart';

import 'package:google_sign_in/google_sign_in.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  User? _currentUser;

  @override
  void initState() {
    super.initState();

    // Escutando as mudanças de estado de autenticação
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<User?> _getUser() async {
    // Se _currentUser não for nulo, retorna o usuário atual
    if (_currentUser != null) return _currentUser;

    try {
      // Se _currentUser for nulo, faz o login com o Google
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      if (googleSignInAccount == null) {
        throw 'Login com o Google cancelado';
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      // Autentica o usuário no Firebase com as credenciais do Google
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      return userCredential.user;
    } catch (error) {
      // Exibe uma mensagem de erro usando o SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao fazer login: $error"),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  void _sendMessage({String? text, File? imgFile}) async {
    final User? user = await _getUser();

    // Verifica se o usuário é nulo, e exibe uma mensagem de erro
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Não foi possível fazer o login. Tente novamente!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Map<String, dynamic> data = {
      "uid": user.uid,
      "senderName": user.displayName,
      "senderPhotoUrl": user.photoURL,
      "time": Timestamp.now(),
    };

    if (imgFile != null) {
      // Referência ao Firebase Storage
      Reference ref = FirebaseStorage.instance
          .ref()
          .child(DateTime.now().millisecondsSinceEpoch.toString());

      // Código para fazer o upload da imagem pode ser adicionado aqui.
    }

    if (text != null) data['text'] = text;

    // Envia a mensagem para o Firestore
    FirebaseFirestore.instance.collection('messages').add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
          title: Text(
            _currentUser != null
                ? 'Olá, ${_currentUser!.displayName}'
                : 'Chat App',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          centerTitle: true,
          elevation: 0,
          actions: [
            _currentUser != null
                ? IconButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      googleSignIn.signOut();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Você saiu com sucesso!"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    },
                    icon: Icon(Icons.exit_to_app),
                  )
                : Container(),
          ]),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('time')
                  .snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    List<DocumentSnapshot> documents =
                        snapshot.data!.docs.reversed.toList();

                    return ListView.builder(
                      itemCount: documents.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        // Cast para Map<String, dynamic> para acessar os dados corretamente
                        var data =
                            documents[index].data() as Map<String, dynamic>;
                        return ChatMessage(
                          data: data,
                        );
                      },
                    );
                }
              },
            ),
          ),
          TextComposer(sendMessage: _sendMessage),
        ],
      ),
    );
  }
}
