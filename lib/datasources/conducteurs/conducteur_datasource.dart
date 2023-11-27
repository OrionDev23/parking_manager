import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:parc_oto/datasources/conducteurs/conducteur_webservice.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../screens/vehicle/documents/document_form.dart';
import '../../screens/vehicle/documents/document_tabs.dart';
import '../parcoto_webservice_response.dart';

class ConducteurDataSource extends ParcOtoDatasource{
  ConducteurDataSource({required super.collectionID, required super.current}){
    repo=ConducteurWebService(data, collectionID, 1);
  }

  late final ConducteurWebService repo;


  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async{
    if (errorCounter != null) {
      errorCounter = errorCounter! + 1;

      if (errorCounter! % 2 == 1) {
        await Future.delayed(const Duration(milliseconds: 1000));
        throw 'Error #${((errorCounter! - 1) / 2).round() + 1} has occured';
      }
    }

    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    final dateFormat2 = DateFormat('y/M/d', 'fr');
    final tstyle = TextStyle(
      fontSize: 10.sp,
    );

    assert(startIndex >= 0);

    // List returned will be empty is there're fewer items than startingAt
    var x = empty
        ? await Future.delayed(const Duration(milliseconds: 500),
            () => ParcOtoWebServiceResponse(0, []))
        : await repo.getData(startIndex, count, sortColumn, sortAscending,
    searchKey: searchKey, filters: filters);

    var r = AsyncRowsResponse(
    x.totalRecords,
    x.data.map((document) {
    return DataRow(
    key: ValueKey<String>(document.value.id),
    onSelectChanged: selectC == true
    ? (value) {
    if (value == true) {
    selectRow(document.value);
    }
    }
        : null,
    cells: [
    DataCell(SelectableText(
    document.value.nom,
    style: tstyle,
    )),
    DataCell(SelectableText(document.value.vehicle?.matricule ?? '',
    style: tstyle),
    onTap: (){
    showMyVehicule(document.value.vehicle?.matricule);
    }

    ),
    DataCell(SelectableText(
    document.value.dateExpiration!=null?
    dateFormat2.format(ClientDatabase.ref.add(
    Duration(milliseconds: document.value.dateExpiration!))):'',
    style: tstyle)),
    DataCell(SelectableText(
    document.value.dateModif!=null?
    dateFormat.format(document.value.dateModif!):'',
    style: tstyle)),
    DataCell(f.FlyoutTarget(
    controller: document.value.controller,
    child: IconButton(
    splashRadius: 15,
    onPressed: () {
    document.value.controller.showFlyout(builder: (context) {
    return f.MenuFlyout(
    items: [
    f.MenuFlyoutItem(
    text: const Text('mod').tr(),
    onPressed: () {
    Navigator.of(current).pop();
    late f.Tab tab;
    tab = f.Tab(
    key: UniqueKey(),
    text: Text(
    '${"mod".tr()} ${'document'.tr().toLowerCase()} ${document.value.nom}'),
    semanticLabel:
    '${'mod'.tr()} ${document.value.nom}',
    icon: const Icon(Bootstrap.car_front),
    body: DocumentForm(
    vd: document.value,
    ),
    onClosed: () {
    DocumentTabsState.tabs.remove(tab);

    if (DocumentTabsState.currentIndex.value >
    0) {
    DocumentTabsState.currentIndex.value--;
    }
    },
    );
    final index =
    DocumentTabsState.tabs.length + 1;
    DocumentTabsState.tabs.add(tab);
    DocumentTabsState.currentIndex.value =
    index - 1;
    }),
    f.MenuFlyoutItem(
    text: const Text('delete').tr(),
    onPressed: () {
    showDeleteConfirmation(document.value);
    }),
    ],
    );
    });
    },
    icon: const Icon(Icons.more_vert_sharp)),
    )),
    ],
    );
    }).toList());

    return r;
  }

  @override
  void showDeleteConfirmation(c) {
    // TODO: implement showDeleteConfirmation
  }
  
}