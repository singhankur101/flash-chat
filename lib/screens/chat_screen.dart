import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
final _firestore=FirebaseFirestore.instance;
User loggedInUser;


class ChatScreen extends StatefulWidget {
  static const String id='chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messagesTextController=TextEditingController();
  final _auth=FirebaseAuth.instance;

  String messageText;
  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }
  void getCurrentUser  () async
  {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    }
    catch(e)
    {
      print(e);
    }
  }

  void messagesStream() async
  {
    Stream<QuerySnapshot<Map<String, dynamic>>> messages =await _firestore.collection('messages').snapshots();
    messages.forEach((element) {
      element.docs.forEach((doc) {
        print(doc.data());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                messagesStream();
                //_auth.signOut();
                //Navigator.pop(context);

              }),
        ],
        title: Text('⚡Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messagesTextController,
                      onChanged: (value) {
                        messageText=value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //---------------
                      messagesTextController.clear();
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'time': FieldValue.serverTimestamp()
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('messages')
      .orderBy('time', descending: false)
          .snapshots(),
      builder: (context,snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),

          );
        }

        final messages=snapshot.data.docs.reversed;
        List<MessageBubble> messageBubbles= [];
        for(var message in messages)
        {
          final messageText=message['text'];
          final messageSender=message['sender'];
          final messageTime = message['time'] as Timestamp;
          final currentUser=loggedInUser.email;

          final messageBubble=MessageBubble(
            sender: messageSender,
            text: messageText,
            isMe: currentUser==messageSender,
            time: messageTime,
          );

          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10,vertical: 20,),


            children: messageBubbles,
          ),
        );


      },

    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender,this.text,this.isMe,this.time});
  final String sender;
  final String text;
  final bool isMe;
  final Timestamp time;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            ' $sender ${DateTime.fromMillisecondsSinceEpoch(time.seconds * 1000)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),),
          Material(
            borderRadius: isMe ? BorderRadius.only(
                topLeft: Radius.circular(30.0),
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0)) :
            BorderRadius.only(
                topRight: Radius.circular(30.0),
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0)),
            elevation: 5.0,
            color: isMe ? Colors.white : Colors.lightBlueAccent,
            child: Padding(
              padding:  EdgeInsets.symmetric(vertical: 10,horizontal: 20),
              child: Text(

                text,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}