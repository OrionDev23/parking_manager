import 'package:fluent_ui/fluent_ui.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';

class TableStats extends StatelessWidget {
  const TableStats({super.key});

  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return Container(
      height: 50.h,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          boxShadow: kElevationToShadow[2],
          borderRadius: BorderRadius.circular(5),
          color: appTheme.mode==ThemeMode.dark?Colors.grey:appTheme.mode==ThemeMode.light?Colors.white:ThemeMode.system==ThemeMode.light?Colors.white:Colors.grey
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              makeTransactionsIcon(context),
              const SizedBox(
                width: 38,
              ),
              const Text(
                'Alertes',
                style: TextStyle(fontSize: 22),
              ),
            ],
          ),
          SizedBox(
            height: 4.h,
          ),
          Table(
            children: [
              TableRow(
                  decoration: BoxDecoration(
                      color: appTheme.color,
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
            ],
            border: TableBorder.all(
                color: Colors.grey[150]
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                  child: const Text('Voir plus'), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget makeTransactionsIcon(BuildContext context) {
    const width = 40.0;
    var appTheme=context.watch<AppTheme>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: width,
          height: width,
          decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                  color: appTheme.color.withOpacity(0.6),
                  width: 3,
              ),
          ),
          child: Icon(FluentIcons.note_pinned,color: appTheme.color,),
        ),
      ],
    );
  }
}
