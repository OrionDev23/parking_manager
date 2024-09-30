import 'package:easy_localization/easy_localization.dart';

NumberFormat upcFormat = NumberFormat('00000000000', 'fr_FR');
int getLastDigitUPC(String num) {
  int result = 0;
  if (int.tryParse(num) != null) {
    List<String> nums =
    upcFormat.format(int.tryParse(num) ?? 0).toString().split('');

    int odds = 0;
    for (int i = 0; i < nums.length; i += 2) {
      odds += int.tryParse(nums[i]) ?? 0;
    }
    odds *= 3;
    int evens = 0;
    for (int j = 1; j < nums.length-1 ; j += 2) {
      evens += int.tryParse(nums[j]) ?? 0;

    }

    evens += odds;


    evens = evens % 10;


    if(evens!=0){
      result = 10 - evens;
    }
    else{
      result =evens;

    }
  }

  return result;
}

String getFirstTwoLetters(String? string){
  if(string==null || string.isEmpty){
    return 'XX';
  }
  else{
    if(string.length==1){
      return '${string}X';
    }
    else{
      if(string.split(RegExp(' +')).length>1){
        return getInitials(string);
      }
      else{
        return string.substring(0,2);
      }
    }
  }
}

String getInitials(String words) => words.isNotEmpty
    ? words.trim().split(RegExp(' +')).map((s) => s[0]).take(2).join()
    : '';

class FormValidators {
  static bool isEmail(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }
}

