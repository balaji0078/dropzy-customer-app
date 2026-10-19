class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool read;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: '${j['id'] ?? ''}',
        title: j['title'] ?? j['subject'] ?? 'Notification',
        body: j['body'] ?? j['message'] ?? '',
        read: j['read'] == true || j['is_read'] == true,
        createdAt: DateTime.tryParse('${j['created_at'] ?? j['createdAt'] ?? ''}'),
      );
}
