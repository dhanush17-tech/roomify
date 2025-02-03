import 'dart:io';
import 'dart:math';
import 'dart:async';

import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/chatModel.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/messaging/document_request_dialog.dart';
import 'package:roomify_app/views/messaging/document_upload_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:easy_image_viewer/easy_image_viewer.dart';

class ChatMessageScreen extends StatefulWidget {
  final ChatRoom room;

  ChatMessageScreen({required this.room});

  @override
  _ChatMessageScreenState createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  late User otherUser;
  bool _isExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isLoadingListings = true;
  late ChatProvider _chatProvider;
  final ScrollController _scrollController = ScrollController();
  bool _isDisposed = false;
  bool _mounted = true;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  List<Listing> otherUserListings = [];

  @override
  void initState() {
    super.initState();

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    final currentUserId = context.read<AuthProvider>().user?.id;
    otherUser = widget.room.participants.firstWhere(
      (user) => user.id != currentUserId,
      orElse: () => widget.room.participants[0],
    );

    _chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Delay all async operations to after build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isDisposed) {
        // Mark messages as read immediately
        await _chatProvider.markMessagesAsRead(widget.room.id);

        // Load user listings
        final data = await context
            .read<ProfileProvider>()
            .loadUserListings(otherUser.id);

        if (!_isDisposed) {
          setState(() {
            otherUserListings = data;
            _isLoadingListings = false;
          });
        }

        // Connect to WebSocket
        _initializeWebSocket();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mark messages as read when dependencies change (e.g., when returning to the screen)
    if (!_isDisposed) {
      _chatProvider.markMessagesAsRead(widget.room.id);
    }
  }

  void _initializeWebSocket() async {
    if (_isDisposed) return;
    try {
      await _chatProvider.connectToRoom(widget.room.id);
      if (!_isDisposed) {
        setState(() => _isConnected = true);
      }
    } catch (error) {
      if (!_isDisposed) {
        setState(() => _isConnected = false);
        _scheduleReconnect();
      }
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 5), () {
      if (!_isDisposed && !_isConnected) {
        _initializeWebSocket();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mounted = false;

    // Cancel timers and controllers
    _reconnectTimer?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    _expandController.dispose();

    // Schedule WebSocket disconnection for next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider.disconnectFromRoom(widget.room.id);
    });

    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      if (!_isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reconnecting to chat...'),
            duration: Duration(seconds: 2),
          ),
        );
        _initializeWebSocket();
        return;
      }

      _chatProvider.sendMessage(
        widget.room.id,
        _messageController.text,
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF8F8F8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      width: 60,
                      height: 60,
                      child: Hero(
                        tag: 'profile-${widget.room.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                            image: otherUser.profilePhotoUrl != null
                                ? DecorationImage(
                                    fit: BoxFit.cover,
                                    image: CachedNetworkImageProvider(
                                        otherUser.profilePhotoUrl!))
                                : null,
                          ),
                          child: otherUser.profilePhotoUrl == null
                              ? Center(child: Text(otherUser.displayName[0]))
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUser.displayName,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          otherUser.isProfessional == false
                              ? otherUser.age.toString() + ' years old'
                              : otherUser.email,
                          style: TextStyle(
                            color: orangeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                    Spacer(),
                    Container(
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF8F8F8),
                      ),
                      child: IconButton(
                        icon: AnimatedRotation(
                          duration: Duration(milliseconds: 300),
                          turns: _isExpanded ? 0.5 : 0,
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.black),
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                            if (_isExpanded) {
                              _expandController.forward();
                            } else {
                              _expandController.reverse();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Container(
                    padding: EdgeInsets.only(left: 16, right: 16, top: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (otherUser.isProfessional == false) ...[
                          if (otherUser.bio != null) ...[
                            Text(
                              'Bio',
                              style: AppTextStyles.title(
                                  fontSize: 15, color: orangeColor),
                            ),
                            SizedBox(height: 8),
                            Text(
                              otherUser.bio!,
                              style: AppTextStyles.small(
                                fontWeight: FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 16),
                            if (otherUser.preferences?.isNotEmpty == true) ...[
                              Text(
                                'Preferences',
                                style: AppTextStyles.title(
                                    fontSize: 15, color: orangeColor),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: otherUser.preferences!.map((pref) {
                                  return Chip(
                                    label: Text(pref.preference),
                                    backgroundColor:
                                        Colors.grey.withOpacity(0.2),
                                    labelStyle: AppTextStyles.small(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                          SizedBox(height: 16),
                          Text(
                            'Listings',
                            style: AppTextStyles.title(
                                fontSize: 15, color: orangeColor),
                          ),
                          SizedBox(height: 8),
                        ],
                        // the profile listings for the other user
                        if (_isLoadingListings == false &&
                            otherUserListings
                                .where((listing) =>
                                    listing.type == ListingType.Property)
                                .isNotEmpty) ...[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                ...otherUserListings
                                    .where((listing) =>
                                        listing.type == ListingType.Property)
                                    .map((listing) => Padding(
                                          padding: EdgeInsets.only(right: 16),
                                          child: _buildPropertyCard(listing),
                                        )),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          if (!_isConnected)
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              color: Colors.orange.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Reconnecting...',
                    style: TextStyle(color: Colors.orange[900]),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final messages = provider.getMessages(widget.room.id);
                messages.sort((a, b) => a.compareTo(b));

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessage(messages[messages.length - 1 - index]);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Listing listing) {
    var minPriceFloorPlan = (listing.property?.floorPlans == null ||
            listing.property!.floorPlans!.isEmpty)
        ? null
        : listing.user!.isProfessional
            ? listing.property!.floorPlans!
                .reduce((curr, next) => curr.price < next.price ? curr : next)
            : null;
    return GestureDetector(
      onTap: () {
        final latitude = context.read<AuthProvider>().user?.latitude;
        final longitude = context.read<AuthProvider>().user?.longitude;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsScreen(
              listing,
              latitude!,
              longitude!,
            ),
          ),
        );
      },
      child: Container(
        width: 300,
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: listing.property?.imageUrls?.isNotEmpty ?? false
                    ? CachedNetworkImage(
                        imageUrl: listing.property?.imageUrls?.first ?? '',
                        fit: BoxFit.cover,
                        height: 120,
                        width: 300,
                      )
                    : Placeholder(
                        fallbackWidth: 300,
                        fallbackHeight: 120,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        listing.title ?? '',
                        style: AppTextStyles.subtitle(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacer(),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: Colors.grey, size: 20),
                          SizedBox(width: 4),
                          Text(
                            listing.location,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ]),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.bathtub, color: Colors.grey, size: 20),
                        SizedBox(width: 5),
                        Text(
                            '${minPriceFloorPlan?.bathrooms ?? listing.property?.numberOfBathrooms}',
                            style: TextStyle(fontSize: 14)),
                        SizedBox(width: 20),
                        Icon(Icons.bed, color: Colors.grey, size: 20),
                        SizedBox(width: 5),
                        Text(
                            '${minPriceFloorPlan?.bedrooms ?? listing.property?.numberOfBedrooms}',
                            style: TextStyle(fontSize: 14)),
                        Spacer(),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 5, horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.blue.withOpacity(0.1),
                            ),
                            child: Text(
                              "\$${minPriceFloorPlan?.price ?? listing.price}/month ",
                              style: AppTextStyles.small(
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                                fontSize: 14,
                              ),
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
  }

  Widget _buildMessage(ChatMessage message) {
    if (message.isDeleted) {
      return SizedBox.shrink();
    }

    final currentUserId = context.read<AuthProvider>().user?.id;
    final isMe = message.senderId == currentUserId;

    return GestureDetector(
      onLongPress: isMe ? () => _showDeleteDialog(message) : null,
      child: message.type == 'DOCUMENT_REQUEST'
          ? _buildDocumentRequestMessage(message)
          : _buildTextMessage(message),
    );
  }

  Widget _buildTextMessage(ChatMessage message) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final isMe = message.senderId == currentUserId;
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? Color(0xFF2B3F6C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  timeago.format(message.createdAt, locale: 'en'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          PopupMenuButton<String>(
            icon: Icon(Icons.attach_file),
            onSelected: (value) {
              if (value == 'request_documents') {
                _showRequestDocumentDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'request_documents',
                child: Row(
                  children: [
                    Icon(Icons.description),
                    SizedBox(width: 8),
                    Text('Request Documents'),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Say something...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 12),
          InkWell(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: orangeColor,
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRequestMessage(ChatMessage message) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final isMe = message.senderId == currentUserId;
    final isRecipient = message.type == 'DOCUMENT_REQUEST' && !isMe;
    final isPending = message.documentRequestStatus == 'PENDING';
    final isFulfilled = message.documentRequestStatus == 'FULFILLED';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFulfilled
            ? Colors.green[100]
            : (isMe ? Colors.blue[100] : Colors.blueGrey.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFulfilled ? Colors.green : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Document Request',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isFulfilled ? Colors.green[900] : Colors.black87,
                ),
              ),
              Row(
                children: [
                  //delete icon

                  if (isPending)
                    Text(
                      'Pending',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  SizedBox(width: 10),
                  //delete should only be shown if the message is my the current user
                  if (isMe)
                    GestureDetector(
                      onTap: () => _showDeleteDialog(message),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete,
                            color: Colors.redAccent, size: 20),
                      ),
                    ),
                ],
              )
            ],
          ),
          SizedBox(height: 8),
          if (message.requestedDocuments != null) ...[
            ...message.requestedDocuments!
                .where((doc) => doc != DocumentType.Custom)
                .map(
                  (doc) => Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      '• ${doc.toString().split('.').last.replaceAll(RegExp(r'(?=[A-Z])'), ' ')}',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            if (message.customDocumentName != null)
              Padding(
                padding: EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  '• ${message.customDocumentName}',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
          if (!isMe && isPending) ...[
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () =>
                  _showDocumentUploadDialog(message.documentRequestId!),
              icon: Icon(Icons.upload_file),
              label: Text('Upload Documents'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentSubmissionMessage(ChatMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents Submitted',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: message.submittedDocuments!
                .map(
                  (url) => InkWell(
                    onTap: () => _openDocument(url),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_present, size: 20),
                          SizedBox(width: 4),
                          Text('View Document'),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _showRequestDocumentDialog() {
    if (!mounted) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    BuildContext? loadingDialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: DocumentRequestDialog(
          recipientId: otherUser.id,
          onRequest: (documents, {String? customDocumentName}) async {
            if (!mounted) return;

            try {
              // Show loading indicator
              await showDialog(
                context: dialogContext,
                barrierDismissible: false,
                builder: (context) {
                  loadingDialogContext = context;
                  return WillPopScope(
                    onWillPop: () async => false,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              );
            } catch (e) {
              print('Error showing loading dialog: $e');
            }

            try {
              await chatProvider.requestDocuments(
                widget.room.id,
                otherUser.id,
                documents,
                dialogContext,
                customDocumentName: customDocumentName,
              );

              // Only proceed with navigation if still mounted
              if (!mounted) return;

              // Close loading indicator if it's still showing
              if (loadingDialogContext != null) {
                Navigator.of(loadingDialogContext!).pop();
              }

              // Close the document request dialog
              Navigator.of(dialogContext).pop();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Document request sent successfully')),
              );
            } catch (e) {
              // Only handle error if still mounted
              if (!mounted) return;

              // Close loading indicator if it's still showing
              if (loadingDialogContext != null) {
                Navigator.of(loadingDialogContext!).pop();
              }

              // Show error message but keep dialog open
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Failed to send document request: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  void _showDocumentUploadDialog(String requestId) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => DocumentUploadDialog(
        requestId: requestId,
        onSubmit: (urls) async {
          await context.read<ChatProvider>().submitDocuments(
                widget.room.id,
                requestId,
                urls,
              );
          Navigator.pop(context, urls);
        },
      ),
    );

    if (result != null) {
      // Handle successful document submission
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Documents submitted successfully')),
      );
    }
  }

  void _openDocument(String url) async {
    try {
      final uri = Uri.parse(url.replaceFirst(
          "undefined", "https://pub-167ff6c23d994b42b8bae57e8cb2381f.r2.dev"));

      final fileName = uri.pathSegments.last.toLowerCase();

      if (fileName.endsWith('.pdf')) {
        await _openPdfDocument(uri);
      } else if (fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.png')) {
        await _openImageDocument(uri);
      } else {
        throw 'Unsupported file type';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening document: $e')),
      );
    }
  }

  Future<void> _openPdfDocument(Uri uri) async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('PDF Document'),
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Container(),

            // FutureBuilder<PDFDocument>(
            //   future: (() async {
            //     final response = await http.get(uri);
            //     final dir = await getTemporaryDirectory();
            //     final fileName = uri.pathSegments.last;
            //     final file = File('${dir.path}/$fileName');
            //     await file.writeAsBytes(response.bodyBytes);
            //     return PDFDocument.fromFile(file);
            //   })(),
            //   builder: (context, snapshot) {
            //     if (snapshot.connectionState == ConnectionState.waiting) {
            //       return Center(child: CircularProgressIndicator());
            //     }

            //     if (snapshot.hasError) {
            //       return Center(
            //           child: Text('Error loading PDF: ${snapshot.error}'));
            //     }

            //     if (!snapshot.hasData) {
            //       return Center(child: Text('Failed to load PDF'));
            //     }

            //     return PDFViewer(
            //       document: snapshot.data!,
            //       showPicker: false,
            //       showNavigation: true,
            //     );
            //   },
            // ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening PDF: $e')),
      );
    }
  }

  Future<void> _openImageDocument(Uri uri) async {
    try {
      final imageProvider = NetworkImage(uri.toString());

      showImageViewer(
        context,
        imageProvider,
        swipeDismissible: true,
        doubleTapZoomable: true,
        useSafeArea: true,
        immersive: false,
        onViewerDismissed: () {
          // Handle viewer dismissed if needed
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening image: $e')),
      );
    }
  }

  void _showDeleteDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (message.type == 'DOCUMENT_REQUEST') {
                  await context.read<ChatProvider>().deleteDocumentRequest(
                        widget.room.id,
                        message.id,
                        message.documentRequestId!,
                      );
                } else {
                  await context.read<ChatProvider>().deleteMessage(
                        widget.room.id,
                        message.id,
                      );
                }
              } catch (e) {
                if (_mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete message: $e')),
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDocumentRequestDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Document Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this document request?'),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<ChatProvider>().deleteDocumentRequest(
                      widget.room.id,
                      message.id,
                      message.documentRequestId!,
                    );
                if (_mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Document request deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (_mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete document request: $e'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildPropertyImageShimmer() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: FadeShimmer(
      height: 120,
      width: double.infinity,
      radius: 15,
      highlightColor: Colors.grey[200]!,
      baseColor: Colors.grey[300]!,
    ),
  );
}
