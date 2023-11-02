import 'package:parc_oto/serializables/parc_user.dart';

class ProfilUtilitis{
 static  String getFirstLetters(ParcUser? user) {
    String result = "";
    if (user != null) {
      if (user.name!=null && user.name!.isNotEmpty) {
        var s = user.name!.split(' ');
        if (s.length > 1) {
          result = s[0][0] + s[1][0];
        } else {
          result = user.name![0] + user.name![1];
        }
      }
      else {
        result = user.email[0] + user.email[1];
      }
    }
    return result;
  }
}