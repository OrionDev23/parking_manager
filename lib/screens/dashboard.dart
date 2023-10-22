import 'package:fluent_ui/fluent_ui.dart';
import 'package:parking_manager/theme.dart';
import 'package:parking_manager/utilities/theme_colors.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../widgets/button_container.dart';
import '../widgets/page_header.dart';
import 'dashboard/transaction_chart.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const smallSpace = SizedBox(
      width: 5,
    );
    var appTheme=context.watch<AppTheme>();

    return ScaffoldPage(
      header: const PageTitle(text: 'home'),
      content: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ButtonContainer(
                  icon: FluentIcons.car,
                  text: 'Vehicules actifs',
                ),
                smallSpace,
                ButtonContainer(
                    icon: FluentIcons.edit_event, text: 'Reservation'),
                smallSpace,
                ButtonContainer(icon: FluentIcons.people, text: 'Clients'),
                smallSpace,
                ButtonContainer(
                  icon: FluentIcons.report_alert,
                  text: 'Aide',
                  textList: "Obtenir de l'aide",
                  showBothLN: false,
                  showCounter: false,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    height: 50.h,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      boxShadow: kElevationToShadow[2],
                      borderRadius: BorderRadius.circular(5),
                      color: appTheme.mode==ThemeMode.dark?Colors.grey:appTheme.mode==ThemeMode.light?Colors.white:ThemeMode.system==ThemeMode.light?Colors.white:Colors.grey
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Table(
                          children: [
                            TableRow(
                                decoration: BoxDecoration(
                                    color: ThemeColors.orange,
                                    boxShadow: kElevationToShadow[2]),
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('No'),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Transaction'),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Date'),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Montant'),
                                  ),
                                ]),
                            const TableRow(children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('5'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Vidange'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('10/10/2019'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('10000.00 DA'),
                              ),
                            ]),
                            const TableRow(children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('5'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Vidange'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('10/10/2019'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('10000.00 DA'),
                              ),
                            ]),
                            const TableRow(children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('5'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Vidange'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('10/10/2019'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('10000.00 DA'),
                              ),
                            ]),
                            const TableRow(children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('5'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Vidange'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('10/10/2019'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('10000.00 DA'),
                              ),
                            ]),
                            const TableRow(children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('5'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Vidange'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('10/10/2019'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('10000.00 DA'),
                              ),
                            ]),
                            const TableRow(children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('5'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Vidange'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('10/10/2019'),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('10000.00 DA'),
                              ),
                            ]),
                          ],
                          border: TableBorder.all(
                            color: Colors.grey[150]
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        FilledButton(
                            child: const Text('Voir plus'), onPressed: () {}),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      boxShadow: kElevationToShadow[2],
                      borderRadius: BorderRadius.circular(5),
                        color: appTheme.mode==ThemeMode.dark?Colors.grey:appTheme.mode==ThemeMode.light?Colors.white:ThemeMode.system==ThemeMode.light?Colors.white:Colors.grey

                    ),
                    width: 40.w,
                    height: 50.h,
                    child: TransactionChart()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
