class Environment {
  static const String stage = 'test'; // Change to 'prod'||'test' for production
}

class BackendProperties {
  // Option 2: Using AWS EC2 instance (uncomment if needed)
  static Uri baseUrl = Uri(
    scheme: 'https',
    host: 'ec2-15-207-55-211.ap-south-1.compute.amazonaws.com ',
    port: 3001,
  );
  static Map<String, String> getHeaders({String? uid}) {
    //TODO: Eventually Bring all Auth headers into the main header
    Map<String, String> headers = {
      // 'stage': Environment.stage, // Add the stage header
    };
    if (uid != null) {
      headers['Authorization'] = 'Bearer $uid';
    }
    return headers;
  }

  static Uri resetUri = baseUrl.replace(path: '/auth/forgot');
  static Uri loginUri = baseUrl.replace(path: '/auth/login');
  static Uri userInfoUri = baseUrl.replace(path: '/auth/me');
  static Uri registerUri = baseUrl.replace(path: '/auth/register');

  static Uri roomDataUri(String email) =>
      baseUrl.replace(path: '/rooms/user', queryParameters: {'email': email});

  static Uri allRoomDataUri = baseUrl.replace(path: '/rooms/get-all');
  static Uri roomMessageUri(String tempRoomId) => baseUrl.replace(
      path: 'messages/roomMsg', queryParameters: {'roomId': tempRoomId});

  static Uri allTasksUri = baseUrl.replace(path: '/tasks');
  static Uri taskInstanceByIdUri = baseUrl.replace(path: '/tasks/user');

  static Uri taskDetailUri(String taskId) =>
      baseUrl.replace(path: '/tasks/$taskId');

  static Uri instanceCheckpointUri(
          int instanceId) => // getting all checkpoints and updating checkpoints is done on the same URI.
      baseUrl.replace(path: '/instance/$instanceId/checkpoints');
  static Uri addCheckpointUri(
          int instanceId) => // getting all checkpoints and updating checkpoints is done on the same URI.
      baseUrl.replace(path: '/instance/$instanceId/checkpoints');

  static Uri instanceLinksUri(int instanceId) =>
      baseUrl.replace(path: '/instance/$instanceId/links');
  static Uri addInstanceLinkUri(int instanceId) =>
      baseUrl.replace(path: '/instance/$instanceId/links');

  static Uri eventsUri = baseUrl.replace(path: '/event');
  static Uri websocketUri = baseUrl.replace(path: '/ws');
  static Uri lastSeenUri(String emailId, String roomId) =>
      baseUrl.replace(path: '/user/$emailId/$roomId/last-seen');

  static Uri activeMemberUri(String roomId) => baseUrl
      .replace(path: '/members/get', queryParameters: {"roomId": roomId});

  static Uri updateLastSeenUri(String emailId, String roomId) {
    return baseUrl.replace(path: '/user/$emailId/$roomId/seen');
  }

  static Uri announcementUri(String emailId) => baseUrl
      .replace(path: 'rooms/announcement', queryParameters: {'email': emailId});

  static Uri uploadUri = baseUrl.replace(path: '/file/upload');
  static Uri deleteUpload(String publicId) => baseUrl
      .replace(path: '/file/delete', queryParameters: {'publicKey': publicId});

  static Uri updateDp = baseUrl.replace(path: '/user/update-dp');
  static String recruitmentUri = "https://zine.co.in/login";
}
