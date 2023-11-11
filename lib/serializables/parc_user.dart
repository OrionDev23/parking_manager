class ParcUser{
  final String? name;
  final String email;
  final int? datec;
  final int? datea;
  final int? datel;
  final String? tel;
  final String id;

  final String? avatar;

  ParcUser({this.avatar, this.name, required this.email, this.datec, this.datea, this.datel, this.tel, required this.id});

Map<String,dynamic> toJson(){
  return {
    'name':name,
    'email':email,
    'datec':datec,
    'datel':datel,
    'datea':datea,
    'tel':tel,
    'id':id,
    'avatar':avatar,
  };
}


factory ParcUser.fromJson(Map<String,dynamic> json){

  return ParcUser(
    email: json['email'],
    avatar: json['avatar'],
    name: json['name'],
    datea: json['datea'],
    datec: json['datec'],
    datel: json['datel'],
    tel:json['tel'],
    id: json['id'],

  );
}
}