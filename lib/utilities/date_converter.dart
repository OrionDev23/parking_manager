import 'package:easy_localization/easy_localization.dart';

class DateConverter{
  static String? adjustDate(String? date){

    if(date==null){
      return date;
    }
    if(date.contains('/')){
      var splited0=date.split(' ');
      var splited=splited0[0].split('/');
      if(splited0.length>1){
        if(splited.length>1){
          if(splited[0].length<=2){
            return '${splited[0]}-${splited[1]}-${splited[2]} ${splited0[1]}';
          }
          else{
            return '${splited[2]}-${splited[1]}-${splited[0]} ${splited0[1]}';
          }
        }
        else{
          return date;
        }
      }
      else{
        if(splited.length>1){
          if(splited[0].length<=2){
            return '${splited[0]}-${splited[1]}-${splited[2]}';
          }
          else{
            return '${splited[2]}-${splited[1]}-${splited[0]}';
          }
        }
        else{
          return date;
        }
      }

    }
    else if(date.contains('-')){
      var splited2=date.split(' ');
      var splited3=splited2[0].split('-');
      if(splited2.length>1){
        if(splited3.length>2){
          if(splited3[0].length<=2){
            return '${splited3[2]}-${splited3[1]}-${splited3[0]} ${splited2[1]}';
          }
          else{
            return date;
          }
        }
        else{
          return date;
        }
      }
      else{
        if(splited3.length>2){
          if(splited3[0].length<=2){
            return '${splited3[2]}-${splited3[1]}-${splited3[0]}';
          }
          else{
            return date;
          }
        }
        else{
          return date;
        }
      }
    }
    else{
      return date;
    }
  }

  static String? formatDate(String? date,[int type=0]){
    if(date==null){
      return date;
    }
    if(date.contains('/') && date.contains(':')){
      return date;
    }
    DateTime? datet=DateTime.tryParse(adjustDate(date)??'/');
    NumberFormat formatter=NumberFormat('00','fr_FR');

    if(datet==null){
      return '/';
    }
    else{
      if(type==0){
        return '${formatter.format(datet.day)}/${formatter.format(datet.month)}/${datet.year}';
      }
      else{
        return '${formatter.format(datet.day)}/${formatter.format(datet.month)}/${datet.year} ${formatter.format(datet.hour)}:${formatter.format(datet.minute)}:${formatter.format(datet.second)}';
      }
    }

  }

  static DateTime? getDate(String? date){
    if(date==null){
      return null;
    }
    return DateTime.tryParse(adjustDate(date)??'/');

  }
}