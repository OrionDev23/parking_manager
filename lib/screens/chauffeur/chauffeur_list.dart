
import 'package:adv_log_fact/screens/panes.dart';
import 'package:adv_log_fact/utilitaire/data_sources/chauffeur_datasource.dart';
import 'package:adv_log_fact/utilitaire/database_downloader.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:paged_datatable/paged_datatable.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../serializable.dart';
import '../../theme.dart';
import 'chauffeur_form.dart';
import 'chauffeur_tabs.dart';

class ChauffeurList extends StatefulWidget {
  const ChauffeurList({super.key,});

  @override
  ChauffeurListState createState() => ChauffeurListState();
}

class ChauffeurListState extends State<ChauffeurList> {
  double progress = 0;

  GlobalKey viewKey = GlobalKey(debugLabel: 'Scaffold key');

  GlobalKey pag=GlobalKey();
  final tableController = PagedDataTableController<String, KeyValue<String,Facture>>();
  late ChauffeurDataSource _chauffeurDataSource;
  List<DataColumn2> get _columns{
    return [DataColumn2(
      label: const Text('Nom'),
      size: ColumnSize.L,
      onSort: (columnIndex,ascending)=>
          sort<String>(0, ascending),
    ),
      DataColumn2(
        label: const Text('Type d\'engin'),
        size: ColumnSize.M,
        onSort: (columnIndex,ascending)=>
            sort<String>(1, ascending),
      ),
      DataColumn2(
        label: const Text('Mat. tracteur'),
        size: ColumnSize.M,
        onSort: (columnIndex,ascending)=>
            sort<String>(2, ascending),
      ),
      DataColumn2(
        label: const Text('Mat. remorque'),
        size: ColumnSize.M,
        onSort: (columnIndex,ascending)=>
            sort<String>(3, ascending),
      ),
      DataColumn2(
        label: const Text('Date dernière modif.'),
        size: ColumnSize.L,
        onSort: (columnIndex,ascending)=>
            sort<String>(3, ascending),
      ),
      if(MyAppState.userType.value==0 ||MyAppState.userType.value==3 )
        const DataColumn2(label: Text(''),
        size:ColumnSize.S,
      ),

    ];}

  int? _sortColumnIndex;
  bool _ascending=false;

  bool loading = true;
  bool _initialized = false;
  PaginatorController? _controller;

  TextEditingController searchC=TextEditingController();

  bool error = false;

  @override
  void initState() {
    if (DatabaseGetter.errorChauffeur) {
      downloadData();
    }
    else{
      createList();

    }
    super.initState();
  }

  @override
  void dispose() {
    _chauffeurDataSource.dispose();
    super.dispose();
  }

  void downloadData() async {
    loading = true;
    progress = 0;

    try {
      await DatabaseGetter().downloadAllChauffeurs();
    } catch (e) {
      error = true;
      if(mounted){
        setState(() {
        });
      }

      return;
    }

    if(mounted){

      setState(() {
        progress = 80;
      });}
    createListOnDownload();
  }



  void createList() async{

    _chauffeurDataSource=ChauffeurDataSource(context);
    _controller = PaginatorController();
    _initialized=true;
    setState(() {
      progress=100;
    });
    await Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {});
    setState(() {
      loading = false;
    });
  }

  void createListOnDownload() async{
    _chauffeurDataSource=ChauffeurDataSource(context);
    _controller = PaginatorController();
    _initialized=true;
    progress=100;

    if(mounted){

      setState(() {
      });}
    await Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {});
    setState(() {
      loading = false;
    });
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _chauffeurDataSource = ChauffeurDataSource(
        context,);
      _controller = PaginatorController();
      _initialized = true;
    }
  }


  void sort<T>(
      int columnIndex,
      bool ascending,
      ) {
    _chauffeurDataSource.sort<T>(columnIndex, ascending);

    setState(() {

      _sortColumnIndex = columnIndex;
      _ascending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {

    final appTheme = context.watch<AppTheme>();
    if (loading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Téléchargement des Chauffeurs...'),
          ProgressBar(
            value: progress,
          ),
        ],
      );
    }

    if (error) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Probleme de connexion'),
          const SizedBox(
            height: 10,
          ),
          IconButton(
              icon: const Icon(FluentIcons.repeat_all), onPressed: downloadData)
        ],
      );
    }
    return ValueListenableBuilder(
      valueListenable: PanesListState.signedIn,
      builder:(context,value,child){
        if(DatabaseGetter.errorChauffeur && value){
          downloadData();
        }
        return ScaffoldPage(
          key: viewKey,
          header: PageHeader(
            title: Row(
              children: [
                const Text('List des Chauffeurs'),
                const SizedBox(width: 10,),
                Button(
                    onPressed: downloadData,
                    child: Row(children: const [
                      Text('Actualiser'),
                      SizedBox(width: 5,),
                      Icon(FluentIcons.repeat_all),
                    ],
                    )),
              ],
            ),
          ),
          content:
          PaginatedDataTable2(
            key: pag,
            header:  Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if(MyAppState.userType.value==0 || MyAppState.userType.value==3)
                  FilledButton(
                    onPressed: (){
                      Tab? tab;
                      tab=Tab(
                        text: const Text('Nouveau chauffeur'),
                        body: ChauffeurForm(),
                        icon: const Icon(FluentIcons.edit_contact),
                        semanticLabel: 'Nouveau chauffeur',
                        onClosed: (){
                          ChauffeurTabsState.tabs.remove(tab);
                          if (ChauffeurTabsState.currentIndex > 0) ChauffeurTabsState.currentIndex--;
                          ChauffeurTabsState.changing.value++;
                        },);
                      ChauffeurTabsState.tabs.add(tab);
                      ChauffeurTabsState.currentIndex=ChauffeurTabsState.tabs.length-1;
                      ChauffeurTabsState.changing.value++;
                    },
                    child: Row(
                      children: const [
                        Icon(FluentIcons.bill),
                        SizedBox(width: 5,),
                        Text('Nouveau'),
                      ],
                    ),
                  ),
                const SizedBox(
                  width: 10,
                ),
                SizedBox(
                  width: 300,
                  height: 30,
                  child: TextBox(
                    controller: searchC,
                    suffix: const Icon(FluentIcons.search),
                    placeholder: 'Recherche',
                    placeholderStyle: const TextStyle(fontSize: 12),
                    onEditingComplete: (){
                      setState(() {

                      });
                    },
                  ),
                ),
              ],
            ),
            horizontalMargin: 20,
            columnSpacing: 5,
            renderEmptyRowsInTheEnd: false,
            fit: FlexFit.tight,
            sortColumnIndex: _sortColumnIndex,
            initialFirstRowIndex: 0,
            onPageChanged: (rowIndex) {

            },
            controller: _controller,
            showCheckboxColumn: false,
            sortAscending: _ascending,
            sortArrowIcon: FluentIcons.sort_up, // custom arrow
            onSelectAll: _chauffeurDataSource.selectAll,
            sortArrowAnimationDuration:
            const Duration(milliseconds: 0),
            border: TableBorder(
                horizontalInside:  BorderSide(color:appTheme.mode==ThemeMode.dark?Colors.white:Colors.black, width: 1)),
            columns:  _columns,
            source: ChauffeurDataSource(
              context,
              _sortColumnIndex??4,
              _ascending,
              searchC.value.text,
              true,
              false,
              true,
            ),

          ),
        );},);
  }

}
