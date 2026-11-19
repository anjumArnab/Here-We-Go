import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/chat/providers/chat_provider.dart';
import '../../features/connection/providers/connection_provider.dart';
import '../../features/chat/views/chat_page.dart';

/// App bar chat button with an unread-messages badge.
class ChatActionButton extends StatelessWidget {
  const ChatActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConnectionProvider, ChatProvider>(
      builder: (context, connectionProvider, chatProvider, _) {
        return Container(
          margin: EdgeInsets.only(right: AppTheme.spacingSmall),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            shape: BoxShape.circle,
            boxShadow: [AppTheme.lightShadow],
          ),
          child: Badge(
            isLabelVisible: chatProvider.unreadCount > 0,
            label: Text('${chatProvider.unreadCount}'),
            child: IconButton(
              onPressed:
                  connectionProvider.isConnected
                      ? () {
                        chatProvider.clearUnreadCount();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatPage(),
                          ),
                        );
                      }
                      : null,
              icon: Icon(
                Icons.chat_bubble_outline,
                color:
                    connectionProvider.isConnected
                        ? AppTheme.textDark
                        : AppTheme.gray300,
              ),
              tooltip: 'Chat',
            ),
          ),
        );
      },
    );
  }
}
