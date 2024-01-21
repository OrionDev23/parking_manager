class PNotification {
  final String id;
  final String title;
  final int type;
  final DateTime date;


  PNotification({required this.id,required this.title,required this.type,required this.date});

  @override
  bool operator ==(Object other) {
    return other is PNotification && other.id==id;
  }

  @override
  int get hashCode => id.hashCode;





}