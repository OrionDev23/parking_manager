import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart' as ez;
import 'package:parc_oto/screens/entreprise/entreprise.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart';

import '../utilities/date_converter.dart';

const midPageNbr = 125;
const firstPageLimit = 105;
const picspace=4;
const lenghtofbig=42;
const double size=60;


class List2PDF {
 List<Map<String,dynamic>> list;

 PageOrientation orientation;


 String? picKey;
 final List<String>keysToInclude;
 String title;
 List2PDF({required this.keysToInclude,this.orientation=PageOrientation
     .portrait,
  required this.list,
  this.picKey,
  required this.title});

 Future<Uint8List> generatePDF () async{
  final doc = Document(

  );
  double nbrLines = getNumberOfTextLines();
  int pageLeft = getPageNumbers(nbrLines);
  final logo = await imageFromAssetBundle('assets/images/logo.webp');

  if (nbrLines <= firstPageLimit) {
   var fpage=await getFirstPage(0, logo);
   doc.addPage(Page(

       orientation: orientation,
       theme: ThemeData(
        defaultTextStyle: const TextStyle(
         fontSize: 12,
        ),
       ),
       pageFormat: PdfPageFormat.a4,
       margin: const EdgeInsets.all(20),
       build: (context) {
        return fpage;
       }));
  } else {
   List<Widget> pages = List.empty(growable: true);
   pages.add(await getFirstPage(pageLeft, logo,));
   int i = 1;
   for (i = 1; i < pageLeft; i++) {
    pages.add(await getOtherPage(pageLeft, i));
   }
   pages.add(await getOtherPage(pageLeft, i));

   for (int j = 0; j < pages.length; j++) {
    doc.addPage(Page(
        orientation: orientation,

        theme: ThemeData(
         defaultTextStyle: const TextStyle(
          fontSize: 12,
         ),
        ),
        pageFormat: PdfPageFormat.a4,
        margin: const EdgeInsets.all(20),
        build: (context) {
         return pages[j];
        }));
   }
  }
  return doc.save();
 }

 int getPageNumbers(double nbrLines){
  int pageLeft = 0;
  if (nbrLines <= firstPageLimit) {
   pageLeft = 0;
  } else {
   if (nbrLines <= midPageNbr+firstPageLimit) {
    pageLeft = 1;
   }
   else {
    int nbr = getIndexOfNbrLines(0, firstPageLimit);
    pageLeft = 1;
    for (int i = nbr + 1; i < list.length; i++) {
     nbr += getIndexOfNbrLines(i, midPageNbr);
     if (nbr >= nbrLines) {
      nbr-=getIndexOfNbrLines(i, midPageNbr);
      if(nbrLines-nbr>midPageNbr){
       pageLeft++;
      }
      break;
     }
     pageLeft++;
    }
   }
  }

  return pageLeft;
 }

 Future<Table> getDesiList(int page, int lastPage,) async{

  List<TableRow> l = [
   TableRow(
       decoration: BoxDecoration(
        color: PdfColor.fromHex('#94a5b0'),
       ),
       children: getHeaders()
   ),
  ];

  double nbrLines = getNumberOfTextLines();
  List<int> maxis=getMax(nbrLines, page, lastPage);
  int lastElement = maxis[1];
  int max = maxis[0];

  for (int i = lastElement; i < max; i++) {
   l.add(
       await getRow(i,nbrLines)
   );
  }
  return Table(
   children: l,
   border: TableBorder.all(

   ),
  );
 }


 List<int> getMax(double nbrLines,int page,int lastPage){

  List<int> result=[0,0];
  if (page == 0) {
   if (nbrLines <= firstPageLimit) {
    result[0] = list.length;
   } else {
    if (nbrLines <= firstPageLimit+midPageNbr) {
     if (nbrLines <= firstPageLimit) {
      result[0]  = list.length - 1;
     } else {
      result[0]  = getIndexOfNbrLines(0, firstPageLimit);
     }
    } else {
     result[0]  = getIndexOfNbrLines(0, firstPageLimit);
    }
   }
   result[1]  = 0;
  }
  else if (page < lastPage) {
   // middle pages
   result[1] =
       getIndexOfNbrLines(0, firstPageLimit + midPageNbr * (page - 1));

   result[0]  = getIndexOfNbrLines(result[1], midPageNbr) + 1;

   if(result[0] >=list.length){
    result[0] =list.length-1;
   }

  }
  else {
   // last page
   if (firstPageLimit + midPageNbr * (page-1) > nbrLines) {
    result[1] = list.length - 1;
   } else {
    result[1] =
        getIndexOfNbrLines(0, firstPageLimit + midPageNbr * (page - 1));
   }
   result[0]  = list.length;
  }

  return result;
 }


 List<Widget> getHeaders(){
  TextStyle th = TextStyle(
   fontSize: 11,
   fontWeight: FontWeight.bold,
  );
  List<Widget> result=List.empty(growable: true);

  result.add(Padding(
   padding: const EdgeInsets.all(2),
   child: Text('N°',style: th))
  );

  for(int i=0;i<keysToInclude.length;i++){
   result.add(Padding(
    padding: const EdgeInsets.all(2),
    child: Text(keysToInclude[i].tr(), style: th,textAlign: TextAlign.center),
   ),);
  }

  return result;
 }


 Future<TableRow> getRow(int index,double nbrLines) async{
  const ts = TextStyle(
   fontSize: 10,
  );
  TableRow tr;

  List<Widget> wids=List.empty(growable: true);
  wids.add(
   Padding(
    padding: index == list.length - 1 && nbrLines<=4
        ? const EdgeInsets.fromLTRB(2, 1, 2, 60)
        : const EdgeInsets.fromLTRB(2, 1, 2, 1),
    child: Text(
     (index+1).toString(),
     textDirection: TextDirection.rtl,
     style: ts,
    ),
   ),
  );
  for(int i=0;i<keysToInclude.length;i++){
   if(picKey!=null && keysToInclude[i]==picKey){
    if(list[index][picKey]!=null && list[index][picKey]!.isNotEmpty){
     wids.add(Center(child:Image(await networkImage(list[index][picKey]!),width: size,height: size)));
    }
    else{
     wids.add(Center(child:Image(await imageFromAssetBundle('assets/images/nopic.png'),width: size/2,height: size/2)));
    }
   }
   else{
    if(keysToInclude[i].toUpperCase().contains('DATE')){
     wids.add(
      Padding(
       padding: index == list.length - 1 && nbrLines<=4
           ? const EdgeInsets.fromLTRB(2, 1, 2, 60)
           : const EdgeInsets.fromLTRB(2, 1, 2, 1),
       child: Text(
        DateConverter.formatDate(list[index][keysToInclude[i]]??'2024'.toString
         (),1)??'2024',
        textDirection: TextDirection.rtl,
        style: ts,
       ),
      ),
     );
    }
    else{
     wids.add(
      Padding(
       padding: index == list.length - 1 && nbrLines<=4
           ? const EdgeInsets.fromLTRB(2, 1, 2, 60)
           : const EdgeInsets.fromLTRB(2, 1, 2, 1),
       child: Text(
        list[index][keysToInclude[i]]??''.toString(),
        textDirection: TextDirection.rtl,
        style: ts,
       ),
      ),
     );
    }

   }


  }
  tr=TableRow(children: wids);
  return tr;

 }

 int getIndexOfNbrLines(int startingIndex, int nbrLines) {
  int nbr = 0;
  int max=0;
  for (int i = startingIndex; i < list.length; i++) {
   if(picKey!=null){
    if(list[i][picKey]!=null && list[i][picKey!]!.isNotEmpty){
     nbr+=picspace;
    }
    else{
     max=getLenghtOfBiggest(list[i]);
     nbr += max % lenghtofbig==0
         ? max ~/ lenghtofbig
         : max ~/ lenghtofbig + 1;
    }
   }
   else{
    max=getLenghtOfBiggest(list[i]);
    nbr += max % lenghtofbig==0
        ? max ~/ lenghtofbig
        : max ~/ lenghtofbig + 1;
   }
   if (nbr > nbrLines) {
    if (i == startingIndex) {
     return startingIndex;
    } else {
     return i - 1;
    }
   }
   else if(nbr==nbrLines){
    return i;
   }
  }
  return list.length;
 }

 double getNumberOfTextLines() {
  double nbr = 0;
  int max=0;
  for (int i = 0; i < list.length; i++) {
   if(picKey!=null){
    if(list[i][picKey]!=null && list[i][picKey!]!.isNotEmpty){
     nbr+=picspace;
    }
    else{
         max=getLenghtOfBiggest(list[i]);
         nbr += max % lenghtofbig==0
             ? max ~/ lenghtofbig
             : max ~/ lenghtofbig + 1;
    }
   }
   else{
    max=getLenghtOfBiggest(list[i]);
    nbr += max % lenghtofbig==0
        ? max ~/ lenghtofbig
        : max ~/ lenghtofbig + 1;
   }

  }
  return nbr;
 }

 int getLenghtOfBiggest(Map<String,dynamic> line){
  int result=0;
  line.forEach((key, value) {
   if(value!=null && value.toString().length>result){
    result=value.toString().length;
   }
  });
  return result;
 }


 Future<Widget> getFirstPage(int lastPage,ImageProvider logo,) async{

  return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
       getHeader(logo),
       Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
        child: Text(title,
            style: TextStyle(
             fontWeight: FontWeight.bold,
             fontSize: 12,
            )),
       ),
       await getDesiList(0, lastPage,),
       Spacer(),
       getFooterNum()
      ]); // Center
 }

 Future<Widget> getOtherPage(int lastPage, int page) async{
  return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
       await getDesiList(page, lastPage,),
       Spacer(),
       getFooterNum(),
      ]);
 }

 Widget getHeader(ImageProvider logo) {
  TextStyle ts=TextStyle(fontWeight: FontWeight.bold);

  return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
       SizedBox(
        height: size,
        child: Row(children: [
         Image(logo, width: size, height: size),
         Spacer(),
         Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(MyEntrepriseState.p!.nom,style: ts),
          Text(MyEntrepriseState.p!.rc??'',style: ts),
          Text(MyEntrepriseState.p!.nif??'',style: ts),
          Text(MyEntrepriseState.p!.art??'',style: ts),
          Text(MyEntrepriseState.p!.adresse,style: ts),
         ]),
         Spacer(),
         Column(
             mainAxisAlignment: MainAxisAlignment.start,
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
              SizedBox(height: 20),
              Text(MyEntrepriseState.p!.email??'',style: ts),
              SizedBox(height: 5),
              Text(MyEntrepriseState.p!.telephone??'',style: ts),
             ]),
        ]),
       ),
       Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        SizedBox(width: 30),
        Text('Date',
            style: TextStyle(
             decoration: TextDecoration.underline,
             fontWeight: FontWeight.bold,
            )),
        SizedBox(width: 30),
        Text(
            DateConverter.formatDate(DateTime.now().toString(),)!,
            style: TextStyle(
             decoration: TextDecoration.underline,
             fontWeight: FontWeight.bold,
            )),
       ]),
      ]);
 }

 Widget getFooterNum() {
  TextStyle ts=TextStyle(fontWeight: FontWeight.bold);

  return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
   Text(MyEntrepriseState.p!.rc??'',style: ts),
   Text(MyEntrepriseState.p!.nif??'',style: ts),
   Text(MyEntrepriseState.p!.art??'',style: ts),
  ]);
 }


}