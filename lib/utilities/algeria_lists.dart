import 'package:dzair_data_usage/commune.dart';
import 'package:dzair_data_usage/daira.dart';
import 'package:dzair_data_usage/dzair.dart';
import 'package:dzair_data_usage/langs.dart';

class AlgeriaList{
  static Dzair? dzair;
  AlgeriaList(){
    dzair??=Dzair();
  }

  List<Commune?> getCommune(String wilayaName) {
    List<Commune?> result = List.empty(growable: true);
    for (var element in dzair!.getWilayat()!) {
      if (element!.getWilayaName(Language.FR) == wilayaName) {
        result.addAll(element.getCommunes()!);
        break;
      }
    }
    return result;
  }
  List<Daira?> getDairas(String wilayaName) {
    List<Daira?> result = List.empty(growable: true);
    for (var element in dzair!.getWilayat()!) {
      if (element!.getWilayaName(Language.FR) == wilayaName) {
        result.addAll(element.getDairas()!);
        break;
      }
    }
    return result;
  }
}