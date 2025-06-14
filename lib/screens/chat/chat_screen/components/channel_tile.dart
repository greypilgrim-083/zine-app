import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zineapp2023/providers/user_info.dart';
import 'package:zineapp2023/screens/chat/chat_screen/view_model/chat_room_view_model.dart';

import '../../../../models/rooms.dart';
import '../../../../models/user.dart';
import '../../../../utilities/date_time.dart';
import '../chat_room.dart';

class Channel extends StatelessWidget {
  final Rooms roomDetail;

  const Channel({super.key, required this.roomDetail});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatRoomViewModel, UserProv>(
        builder: (context, chatVm, userProv, _) {
          UserModel currUser = userProv.getUserInfo;
          return Padding(
            padding: const EdgeInsets.all(5.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChatRoom(
                          email: currUser.email,
                          roomDetail: roomDetail,
                        )));
              },
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(8),
                  ),
                  color: Color.fromRGBO(170, 170, 170, 0.1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Avatar
                      File(roomDetail.dpUrl.toString()).existsSync()
                          ? CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 20,
                        child: chatVm.showProfileImage(roomDetail.dpUrl!, radius: 50.0),
                      )
                          : const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 20,
                        backgroundImage: AssetImage("assets/images/zine_logo.png"),
                      ),

                      // Name - takes up remaining space
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                          child: roomDetail.name != null
                              ? Text(
                            roomDetail.name.toString(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                              : const Text(""),
                        ),
                      ),

                      // Right side - Unread count and timestamp
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Unread messages badge
                          if (roomDetail.unreadMessages != null && roomDetail.unreadMessages! > 0)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color.fromRGBO(47, 128, 237, 1),
                              ),
                              height: 20,
                              width: 20,
                              child: Center(
                                child: Text(
                                  roomDetail.unreadMessages.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),

                          // Spacer between badge and timestamp
                          if (roomDetail.unreadMessages != null && roomDetail.unreadMessages! > 0)
                            const Padding(padding: EdgeInsets.only(right: 8.0)),

                          // Timestamp (only show when no unread messages)
                          if (roomDetail.unreadMessages == null || roomDetail.unreadMessages! == 0)
                            Text(
                              roomDetail.lastMessageTimestamp != null
                                  ? getLastSeenFormat(roomDetail.lastMessageTimestamp!)
                                  : "",
                              style: const TextStyle(
                                color: Color.fromARGB(255, 75, 74, 74),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}