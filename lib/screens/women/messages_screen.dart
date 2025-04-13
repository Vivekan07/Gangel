import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

class MessagesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const MessagesScreen({
    super.key,
    required this.userData,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() => _isLoading = true);

      final womenId = widget.userData['id'];
      print('Current user data: ${widget.userData}'); // Debug print
      print('Loading contacts for women ID: $womenId'); // Debug print

      if (womenId == null) {
        throw Exception('Women ID is required to load contacts');
      }

      // Get guardians from women_guardian collection using womenId
      final guardiansSnapshot = await _firestore
          .collection('women_guardian')
          .where('womenId', isEqualTo: womenId)
          .get();

      print('Found ${guardiansSnapshot.docs.length} guardians'); // Debug print

      final List<Map<String, dynamic>> contactsList = [];
      
      for (var doc in guardiansSnapshot.docs) {
        final data = doc.data();
        print('Guardian data: $data'); // Debug print
        final guardianId = data['guardianId'];
        final guardianEmail = data['guardianEmail'];
        
        if (guardianId == null || guardianEmail == null) {
          print('Warning: Guardian ID or email is null for document ${doc.id}');
          continue;
        }

        // Get guardian details from users collection using ID
        final guardianSnapshot = await _firestore
            .collection('users')
            .doc(guardianId)
            .get();

        if (!guardianSnapshot.exists) {
          print('Warning: No guardian found with ID $guardianId');
          continue;
        }

        final guardianData = guardianSnapshot.data()!;
        
        // Get last message using emails
        final lastMessageSnapshot = await _firestore
            .collection('messages')
            .where('guardianEmail', isEqualTo: guardianEmail)
            .where('womenEmail', isEqualTo: widget.userData['email'])
            .get();

        String lastMessage = 'No messages yet';
        String time = '';
        
        if (lastMessageSnapshot.docs.isNotEmpty) {
          // Sort messages manually to get the latest
          final messages = lastMessageSnapshot.docs;
          messages.sort((a, b) {
            final aTime = (a.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bTime = (b.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });
          
          final messageData = messages.first.data();
          lastMessage = messageData['type'] == 'text' 
              ? messageData['content'] 
              : messageData['type'] == 'image' 
                  ? '📷 Image'
                  : '📍 Location';
          time = _formatTimestamp(messageData['timestamp'] as Timestamp);
        }

        contactsList.add({
          'id': guardianId,
          'email': guardianEmail,
          'name': data['guardianName'] ?? guardianData['name'] ?? 'Unknown',
          'phone': data['guardianPhone'] ?? guardianData['phone'] ?? '',
          'lastMessage': lastMessage,
          'time': time,
        });
      }

      print('Final contacts list: $contactsList'); // Debug print

      if (mounted) {
        setState(() {
          _contacts.clear();
          _contacts.addAll(contactsList);
          _isLoading = false;
        });
      }
      
    } catch (e, stackTrace) {
      print('Error loading contacts: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    
    if (now.difference(date).inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(date).inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
              ),
              child: _contacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No guardians added yet',
                    style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add guardians to start messaging',
                            style: TextStyle(
                              fontSize: 14,
                      color: Colors.grey,
                    ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context); // Go back to previous screen
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add Guardians'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                  ),
                )
              : ListView.builder(
        itemCount: _contacts.length,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
        itemBuilder: (context, index) {
          final contact = _contacts[index];
                    return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    userData: widget.userData,
                                    guardianEmail: contact['email'],
                                    guardianName: contact['name'],
                                  ),
                                ),
                              ).then((_) {
                                // Refresh contacts when returning from chat
                                _loadContacts();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            (contact['name']?[0] ?? '').toUpperCase(),
                            style: const TextStyle(
                                        fontSize: 24,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              contact['name'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              contact['time'] ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                contact['lastMessage'] ?? 'No messages yet',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (contact['unreadCount'] != null && contact['unreadCount'] > 0)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  contact['unreadCount'].toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ),
          );
        },
                    ),
      ),
    );
  }
}

const UPLOAD_THING_TOKEN = 'eyJhcGlLZXkiOiJza19saXZlX2YwM2MzZmU2NDk4MzlkZGMzNTYxNzk4ZWFmMDZkZmQ0Zjc5N2M3YzAzYjAxNjlhMmQ2NGFjYjdhNjVhNmI2ZjciLCJhcHBJZCI6IjdnZzV3YzMyZG0iLCJyZWdpb25zIjpbInNlYTEiXX0=';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String guardianEmail;
  final String guardianName;

  const ChatScreen({
    super.key,
    required this.userData,
    required this.guardianEmail,
    required this.guardianName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  Stream<QuerySnapshot>? _messagesStream;
  bool _isLoading = false;
  bool _isTyping = false;
  Timer? _typingTimer;

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    
    if (now.difference(date).inDays == 0) {
      // Today - show time
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(date).inDays == 1) {
      // Yesterday
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(date).inDays < 7) {
      // Within a week - show day name
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${days[date.weekday - 1]} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      // Older - show date
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void initState() {
    super.initState();
    _setupMessagesStream();
    
    // Add listener to scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Listen to typing changes
    _messageController.addListener(_onTypingChanged);
  }

  void _onTypingChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isTyping = false);
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _setupMessagesStream() {
    print('Setting up message stream:'); // Debug print
    print('Women Email: ${widget.userData['email']}'); // Debug print
    print('Guardian Email: ${widget.guardianEmail}'); // Debug print

    _messagesStream = _firestore
        .collection('messages')
        .where('guardianEmail', isEqualTo: widget.guardianEmail)
        .where('womenEmail', isEqualTo: widget.userData['email'])
        .snapshots();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String type, {String? content, String? mediaUrl}) async {
    try {
      if ((type == 'text' && (content?.trim().isEmpty ?? true)) ||
          (type == 'image' && (mediaUrl?.isEmpty ?? true))) {
        return;
      }

      final messageData = {
        'senderEmail': widget.userData['email'],
        'senderName': widget.userData['name'],
        'guardianEmail': widget.guardianEmail,
        'womenEmail': widget.userData['email'],
        'participants': [widget.userData['email'], widget.guardianEmail],
        'type': type,
        'content': content?.trim(),
        'mediaUrl': mediaUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
      };

      print('Sending message data: $messageData'); // Debug print

      final docRef = await _firestore.collection('messages').add(messageData);

      if (type == 'text') {
        _messageController.clear();
      }
      
      // Update message status to delivered after a delay (simulating delivery)
      Future.delayed(const Duration(seconds: 1), () {
        docRef.update({'status': 'delivered'});
      });
      
      // Scroll to bottom after sending message
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImageToUploadThing(File imageFile) async {
    try {
      // Create form data
      var uri = Uri.parse('https://api.uploadthing.com/uploadFiles');
      var request = http.MultipartRequest('POST', uri);
      
      // Add file
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      
      var multipartFile = http.MultipartFile(
        'files',
        stream,
        length,
        filename: 'chat_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      
      request.files.add(multipartFile);
      
      // Add headers with correct authentication format
      request.headers.addAll({
        'Authorization': 'Bearer $UPLOAD_THING_TOKEN',
        'Accept': 'application/json',
      });

      print('Sending request to UploadThing...'); // Debug print
      print('Request URL: ${uri.toString()}'); // Debug print
      print('Request headers: ${request.headers}'); // Debug print
      
      // Send request
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      print('Response status: ${response.statusCode}'); // Debug print
      print('Response headers: ${response.headers}'); // Debug print
      print('Response body: $responseString'); // Debug print

      if (response.statusCode != 200) {
        print('Upload failed with status: ${response.statusCode}');
        print('Response: $responseString');
        throw Exception('Upload failed: $responseString');
      }

      var jsonResponse = jsonDecode(responseString);
      final List<dynamic> files = jsonResponse['data'] ?? [];
      if (files.isEmpty) {
        throw Exception('No URL in response');
      }

      final fileUrl = files[0]['url'];
      if (fileUrl == null) {
        throw Exception('No URL in response data');
      }

      print('Successfully uploaded image: $fileUrl'); // Debug print
      return fileUrl as String;
    } catch (e) {
      print('Error uploading to UploadThing: $e');
      return null;
    }
  }

  Future<void> _sendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image...')),
        );
      });

      // First compress the image
      final File imageFile = File(image.path);
      final bytes = await imageFile.readAsBytes();
      final kb = bytes.length / 1024;
      final mb = kb / 1024;

      if (mb > 5) {
        throw Exception('Image size must be less than 5MB');
      }

      // Upload to UploadThing
      final imageUrl = await _uploadImageToUploadThing(imageFile);
      
      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Send message with image URL
      await _sendMessage('image', mediaUrl: imageUrl);
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error sending image: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _shareLocation() async {
    try {
      setState(() => _isLoading = true);

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      final locationString = '${position.latitude},${position.longitude}';
      print('Location string: $locationString'); // Debug print

      // Send location message
      await _sendMessage(
        'location',
        content: locationString,
      );

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error sharing location: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing location: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                widget.guardianName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.guardianName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isTyping)
                  Text(
                    'typing...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, color: Colors.black87),
            onPressed: _shareLocation,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text('Clear chat'),
                        onTap: () => Navigator.pop(context),
            ),
            ListTile(
                        leading: const Icon(Icons.block),
                        title: const Text('Block guardian'),
                        onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
        ),
        child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];
                messages.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return aTime.compareTo(bTime);
                });

                return ListView.builder(
                  controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                      // Message is from women if senderEmail matches womenEmail
                      final isFromWomen = message['womenEmail'] == message['senderEmail'];
                      print('Message sender: ${message['senderEmail']}'); // Debug print
                      print('Women email: ${widget.userData['email']}'); // Debug print
                      print('Is from women: $isFromWomen'); // Debug print
                      
                      final timestamp = message['timestamp'] as Timestamp?;
                      final timeString = timestamp != null ? _formatTimestamp(timestamp) : '';

                      return Column(
                        children: [
                          if (index == 0 || _shouldShowDateHeader(
                            index > 0 ? messages[index - 1].data() as Map<String, dynamic> : null,
                            message,
                          ))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                            ),
                            decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatDateHeader(timestamp!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          Align(
                            alignment: isFromWomen ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.only(
                                left: isFromWomen ? 64 : 8,
                                right: isFromWomen ? 8 : 64,
                                bottom: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isFromWomen ? Colors.lightBlue.shade100 : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isFromWomen ? 16 : 4),
                                  bottomRight: Radius.circular(isFromWomen ? 4 : 16),
                              ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                            ),
                                ],
                            ),
                              child: Stack(
                                children: [
                          Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isFromWomen ? 'Women' : 'Guardian',
                              style: TextStyle(
                                fontSize: 10,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        _buildMessageContent(message),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              timeString,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            if (isFromWomen) ...[
                                              const SizedBox(width: 2),
                                              Icon(
                                                message['status'] == 'sent' 
                                                    ? Icons.check
                                                    : Icons.done_all,
                                                size: 12,
                                                color: message['status'] == 'read' 
                                                    ? Colors.blue 
                                                    : Colors.grey.shade600,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
              child: SafeArea(
            child: Row(
              children: [
                IconButton(
                      icon: const Icon(Icons.add),
                      color: Colors.grey.shade700,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Camera'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final XFile? image = await _imagePicker.pickImage(
                                      source: ImageSource.camera,
                                    );
                                    if (image != null) {
                                      _sendImage();
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Gallery'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _sendImage();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.location_on),
                                  title: const Text('Location'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _shareLocation();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                      hintText: 'Type a message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                    ),
                  ),
                ),
                IconButton(
                      icon: Icon(
                        _messageController.text.trim().isEmpty
                            ? Icons.mic
                            : Icons.send,
                        color: Colors.blue,
                      ),
                  onPressed: () {
                    if (_messageController.text.trim().isNotEmpty) {
                          _sendMessage(
                            'text',
                            content: _messageController.text.trim(),
                          );
                    }
                  },
                ),
              ],
                ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  bool _shouldShowDateHeader(Map<String, dynamic>? prevMessage, Map<String, dynamic> currentMessage) {
    final prevTimestamp = prevMessage?['timestamp'] as Timestamp?;
    final currentTimestamp = currentMessage['timestamp'] as Timestamp?;
    
    if (prevTimestamp == null || currentTimestamp == null) return false;
    
    final prevDate = prevTimestamp.toDate();
    final currentDate = currentTimestamp.toDate();
    
    return prevDate.year != currentDate.year ||
           prevDate.month != currentDate.month ||
           prevDate.day != currentDate.day;
  }

  String _formatDateHeader(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year &&
               date.month == now.month &&
               date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildMessageContent(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'image':
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    backgroundColor: Colors.black,
                    leading: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  backgroundColor: Colors.black,
                  body: Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Image.network(
                        message['mediaUrl'],
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
              maxHeight: 200,
            ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message['mediaUrl'],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
              width: 200,
              height: 200,
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / 
                              loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      case 'location':
        return GestureDetector(
          onTap: () {
            final coordinates = message['content'].split(',');
            final lat = double.parse(coordinates[0]);
            final lng = double.parse(coordinates[1]);
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Location')),
                  body: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(lat, lng),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('location'),
                        position: LatLng(lat, lng),
                      ),
                    },
                  ),
                ),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.location_on),
              SizedBox(width: 8),
              Text('View Location'),
            ],
          ),
        );
      default:
        return Text(
          message['content'] ?? '',
          style: TextStyle(
            color: message['senderEmail'] == widget.userData['email']
                ? Colors.black87
                : Colors.black87,
            fontSize: 16,
          ),
        );
    }
  }
}