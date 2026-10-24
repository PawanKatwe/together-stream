class AppConfig {
  // Fixed Private Room
  static const String roomName = 'PP';

  // Secret passcode agreed between Pawan & Priya
  static const String passcode = 'PP@160227';

  // Fixed identities
  static const String userPawan = 'Pawan';
  static const String userPriya = 'Priya';

  // Token server URL (Change this to your deployed Render URL e.g. https://together-stream.onrender.com)
  // For local Wi-Fi testing, use your laptop's local IP (e.g. http://192.168.1.5:3000)
  static String tokenServerUrl = 'https://together-stream-server.onrender.com';

  // Helper to determine partner identity
  static String getPartnerName(String myIdentity) {
    return myIdentity == userPawan ? userPriya : userPawan;
  }
}
