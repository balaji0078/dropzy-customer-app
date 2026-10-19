/// A support ticket (GET /support/tickets).
class SupportTicket {
  final String id;
  final String dcn;
  final String category;
  final String priority;
  final String status;
  final String? customer;
  final String? assignee;

  SupportTicket({
    required this.id,
    required this.dcn,
    required this.category,
    required this.priority,
    required this.status,
    this.customer,
    this.assignee,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> j) => SupportTicket(
        id: '${j['id'] ?? ''}',
        dcn: '${j['dcn'] ?? ''}',
        category: '${j['category'] ?? ''}',
        priority: '${j['priority'] ?? ''}',
        status: '${j['status'] ?? 'open'}',
        customer: j['customer'],
        assignee: j['assignee'],
      );
}
