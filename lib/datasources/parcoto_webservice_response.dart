
class ParcOtoWebServiceResponse<T> {
  ParcOtoWebServiceResponse(this.totalRecords, this.data);

  /// THe total ammount of records on the server, e.g. 100
  final int totalRecords;

  /// One page, e.g. 10 reocrds
  final List<MapEntry<String,T>> data;
}

class UsersWebServiceResponse<S,T>{
  UsersWebServiceResponse(this.totalRecords, this.data);

  /// THe total ammount of records on the server, e.g. 100
  final int totalRecords;

  /// One page, e.g. 10 reocrds
  final List<MapEntry<S,T>> data;
}


