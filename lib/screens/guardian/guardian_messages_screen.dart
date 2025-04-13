import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GuardianMessagesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String guardianId;
  final String guardianEmail;
  
  const GuardianMessagesScreen({
    Key? key,
    required this.userData,
    required this.guardianId,
    required this.guardianEmail,
  }) : super(key: key);

  @override
  State<GuardianMessagesScreen> createState() => _GuardianMessagesScreenState();
}

class _GuardianMessagesScreenState extends State<GuardianMessagesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _contacts = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() => _isLoading = true);

      print('Loading contacts for guardian ID: ${widget.guardianId}'); // Debug print
      print('Guardian email: ${widget.guardianEmail}'); // Debug print

      // Get users who have added this guardian from women_guardian collection
      final usersSnapshot = await _firestore
          .collection('women_guardian')
          .where('guardianId', isEqualTo: widget.guardianId)
          .get();

      print('Found ${usersSnapshot.docs.length} users'); // Debug print

      final List<Map<String, dynamic>> contactsList = [];
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final womenId = data['womenId'];
        final womenEmail = data['womenEmail'];
        
        if (womenId == null || womenEmail == null) {
          print('Warning: Women ID or email is null for document ${doc.id}');
          continue;
        }

        // Get user details from users collection
        final userSnapshot = await _firestore
            .collection('users')
            .doc(womenId)
            .get();

        if (!userSnapshot.exists) {
          print('Warning: No user found with ID $womenId');
          continue;
        }

        final userData = userSnapshot.data()!;

        // Get last message using emails
        final lastMessageSnapshot = await _firestore
            .collection('messages')
            .where('guardianEmail', isEqualTo: widget.userData['email'])
            .where('womenEmail', isEqualTo: womenEmail)
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
          'id': womenId,
          'email': womenEmail,
          'name': userData['name'] ?? 'Unknown',
          'phone': userData['phone'] ?? '',
          'lastMessage': lastMessage,
          'time': time,
          'status': userData['status'] ?? 'Safe',
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
        title: const Text('Messages'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(
                  child: Text(
                    'No messages yet.\nWait for users to add you as their guardian.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            (contact['name']?[0] ?? '').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                contact['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: contact['status'] == 'Safe'
                                    ? Colors.green[100]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                contact['status'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: contact['status'] == 'Safe'
                                      ? Colors.green[900]
                                      : Colors.orange[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact['lastMessage'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              contact['phone'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          contact['time'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                userData: widget.userData,
                                guardianId: widget.guardianId,
                                guardianEmail: widget.guardianEmail,
                                womenId: contact['id'],
                                womenEmail: contact['email'],
                                womenName: contact['name'],
                                womenStatus: contact['status'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String guardianId;
  final String guardianEmail;
  final String womenId;
  final String womenEmail;
  final String womenName;
  final String womenStatus;

  const ChatScreen({
    super.key,
    required this.userData,
    required this.guardianId,
    required this.guardianEmail,
    required this.womenId,
    required this.womenEmail,
    required this.womenName,
    required this.womenStatus,
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

  @override
  void initState() {
    super.initState();
    _setupMessagesStream();
    
    // Add listener to scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    print('Setting up message stream for guardian:'); // Debug print
    print('Guardian Email: ${widget.userData['email']}'); // Debug print
    print('Women Email: ${widget.womenEmail}'); // Debug print

    _messagesStream = _firestore
        .collection('messages')
        .where('guardianEmail', isEqualTo: widget.userData['email'])
        .where('womenEmail', isEqualTo: widget.womenEmail)
        .snapshots();
  }

  Future<void> _sendMessage(String type, {String? content, String? mediaUrl}) async {
    try {
      if ((type == 'text' && (content?.trim().isEmpty ?? true)) ||
          (type == 'image' && (mediaUrl?.isEmpty ?? true))) {
        return;
      }

      // Create message data with server timestamp
      final messageData = {
        'senderEmail': widget.userData['email'],
        'senderName': widget.userData['name'],
        'guardianId': widget.guardianId,
        'guardianEmail': widget.guardianEmail,
        'womenId': widget.womenId,
        'womenEmail': widget.womenEmail,
        'participants': [widget.guardianEmail, widget.womenEmail],
        'type': type,
        'content': content?.trim(),
        'mediaUrl': mediaUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
      };

      print('Sending message data: $messageData'); // Debug print

      final docRef = await _firestore.collection('messages').add(messageData);
      print('Message sent with ID: ${docRef.id}'); // Debug print

      if (type == 'text') {
        _messageController.clear();
      }
      
      // Scroll to bottom after sending message
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

      setState(() => _isLoading = true);

      // Upload image to Firebase Storage
      final ref = _storage.ref().child('chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(image.path));
      final imageUrl = await ref.getDownloadURL();

      // Send message with image URL
      await _sendMessage('image', mediaUrl: imageUrl);
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error sending image: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending image: $e')),
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
          SnackBar(content: Text('Error sharing location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.womenName),
            Text(
              widget.womenStatus,
              style: TextStyle(
                fontSize: 12,
                color: widget.womenStatus == 'Safe' ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _shareLocation,
          ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              // Implement phone call functionality
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
                  
                  // Sort messages safely handling null timestamps
                  messages.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTime = aData['timestamp'] as Timestamp?;
                    final bTime = bData['timestamp'] as Timestamp?;
                    
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    
                    return aTime.compareTo(bTime);
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index].data() as Map<String, dynamic>;
                      // Message is from guardian if senderEmail matches guardianEmail
                      final isFromGuardian = message['guardianEmail'] == message['senderEmail'];
                      print('Message sender: ${message['senderEmail']}'); // Debug print
                      print('Guardian email: ${widget.guardianEmail}'); // Debug print
                      print('Is from guardian: $isFromGuardian'); // Debug print
                      
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
                            alignment: isFromGuardian ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.only(
                                left: isFromGuardian ? 64 : 8,
                                right: isFromGuardian ? 8 : 64,
                                bottom: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isFromGuardian ? Colors.lightBlue.shade100 : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isFromGuardian ? 16 : 4),
                                  bottomRight: Radius.circular(isFromGuardian ? 4 : 16),
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
                                          isFromGuardian ? 'Guardian' : 'Women',
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
                                            if (isFromGuardian) ...[
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
                      icon: const Icon(Icons.send),
                      color: Colors.blue,
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

  bool _shouldShowDateHeader(Map<String, dynamic>? prevMessage, Map<String, dynamic> currentMessage) {
    if (prevMessage == null) return true;
    
    final prevTimestamp = prevMessage['timestamp'] as Timestamp?;
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
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
        );
    }
  }
} 