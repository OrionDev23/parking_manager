import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/theme.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
class ReparationForm extends StatefulWidget {
  const ReparationForm({super.key});

  @override
  State<ReparationForm> createState() => _ReparationFormState();
}

class _ReparationFormState extends State<ReparationForm> {


  bool r1=false;
  bool r2=false;
  bool r3=false;
  bool r4=false;
  bool r5=false;
  bool r6=false;
  bool r7=false;
  bool r8=false;
  bool r9=false;
  bool r10=false;
  bool r11=false;
  bool r12=false;
  bool r13=false;
  bool r14=false;
  bool r15=false;
  bool r16=false;
  bool r17=false;
  bool r18=false;

  double avdp=100;
  double avgp=100;
  double ardp=100;
  double argp=100;

  bool parAvf=false;
  bool parAvc=false;
  bool parAve=false;
  bool parArf=false;
  bool parArc=false;
  bool parAre=false;

  bool phareG=false;
  bool phareD=false;

  bool feuAVD=false;
  bool feuAVG=false;
  bool feuARD=false;
  bool feuARG=false;
  final tstyle=TextStyle(fontSize: 10.sp);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80.w,
          height: 30.h,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40.w,
                height: 30.h,
                child: Table(
                  border:TableBorder.all(),
                  columnWidths: {
                    0:FixedColumnWidth(10.w),
                    1:FixedColumnWidth(6.w),
                    2:FixedColumnWidth(6.w),
                    3:FixedColumnWidth(4.w),
                    4:FixedColumnWidth(5.w),
                  },
                  children:  [
                    TableRow(
                      children: [
                        TableCell(child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text('PNEUMATIQUE',style:tstyle),
                        )),
                        TableCell(child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text('PARE-BRISE AV',style:tstyle),
                        )),
                        TableCell(child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text('PARE-BRISE AR',style:tstyle),
                        )),
                        TableCell(child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text('PHARE',style:tstyle),
                        )),
                        TableCell(child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text('FEUX',style:tstyle),
                        )),
                      ]
                    ),
                    TableRow(
                        children: [
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              mainAxisAlignment:MainAxisAlignment.start,
                              children: [
                                Text('AVD',style: tstyle,),
                                smallSpace,
                                smallSpace,
                                smallSpace,
                                SizedBox(
                                  width: 5.w,
                                  child: Slider(value: avdp, onChanged: (s){
                                    avdp=s;
                                    setState(() {

                                    });
                                  },
                                    divisions: 100,
                                    label: 'AVD',
                                  ),
                                ),
                                smallSpace,
                                smallSpace,
                                smallSpace,
                                Text('${avdp.ceil()} %',style: tstyle,),
                              ],
                            ),
                          )),
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('FELURE',style: tstyle,),
                                const Spacer(),
                                Checkbox(checked: parAvf, onChanged: (s){
                                  if(s==true){
                                    parAvf=s!;
                                    parAvc=false;
                                    parAve=false;
                                  }
                                  else if(s==false){
                                    parAvf=false;
                                  }
                                  setState(() {
                            
                                  });
                                })
                              ],
                            ),
                          )),
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('FELURE',style: tstyle,),
                                const Spacer(),
                                Checkbox(checked: parArf, onChanged: (s){
                                  if(s==true){
                                    parArf=s!;
                                    parArc=false;
                                    parAre=false;
                                  }
                                  else if(s==false){
                                    parArf=false;
                                  }
                                  setState(() {

                                  });
                                })
                              ],
                            ),
                          )),
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('D',style: tstyle,),
                                const Spacer(),
                                Checkbox(checked: phareD, onChanged: (s){
                                  if(s==true){
                                    phareD=s!;
                                    phareG=false;
                                  }
                                  else if(s==false){
                                   phareD=false;
                                  }
                                  setState(() {

                                  });
                                })
                              ],
                            ),
                          )),
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('AVD',style: tstyle,),
                                const Spacer(),
                                Checkbox(checked: feuAVD, onChanged: (s){
                                  feuAVD=s??false;
                                  setState(() {

                                  });
                                })
                              ],
                            ),
                          )),
                        ]
                    ),
                    TableRow(
                        children: [
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('AVG',style: tstyle,),
                                smallSpace,
                                smallSpace,
                                smallSpace,
                                SizedBox(
                                  width: 5.w,
                                  child: Slider(value: avgp, onChanged: (s){
                                    avgp=s;
                                    setState(() {

                                    });
                                  },
                                    divisions: 100,
                                    label: 'AVG',
                                  ),
                                ),
                                smallSpace,
                                smallSpace,
                                smallSpace,
                                Text('${avgp.ceil()} %',style: tstyle,),
                              ],
                            ),
                          )),
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('CASSURE',style: tstyle,),
                                const Spacer(),
                                Checkbox(checked: parAvc, onChanged: (s){
                                  if(s==true){
                                    parAvf=false;
                                    parAvc=s!;
                                    parAve=false;
                                  }
                                  else if(s==false){
                                    parAvc=false;
                                  }
                                  setState(() {

                                  });
                                })
                              ],
                            ),
                          )),
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('CASSURE',style: tstyle,),
                                const Spacer(),
                                Checkbox(checked: parArc, onChanged: (s){
                                  if(s==true){
                                    parArc=s!;
                                    parArf=false;
                                    parAre=false;
                                  }
                                  else if(s==false){
                                    parArc=false;
                                  }
                                  setState(() {

                                  });
                                })
                              ],
                            ),
                          )),
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('G',style: tstyle,),
                                const Spacer(),
                                Checkbox(checked: phareG, onChanged: (s){
                                  if(s==true){
                                    phareG=s!;
                                    phareD=false;
                                  }
                                  else if(s==false){
                                   phareG=false;
                                  }
                                  setState(() {

                                  });
                                })
                              ],
                            ),
                          )),
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('AVG',style: tstyle,),
                                const Spacer(),

                                Checkbox(checked: feuAVG, onChanged: (s){
                                  feuAVG=s??false;
                                  setState(() {

                                  });
                                })
                              ],
                            ),
                          )),
                        ]
                    ),
                    TableRow(
                        children: [
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('ARD',style: tstyle,),
                                smallSpace,
                                smallSpace,
                                smallSpace,
                                SizedBox(
                                  width: 5.w,
                                  child: Slider(value: ardp, onChanged: (s){
                                    ardp=s;
                                    setState(() {

                                    });
                                  },
                                    divisions: 100,
                                    label: 'ARD',
                                  ),
                                ),
                                smallSpace,
                                smallSpace,
                                smallSpace,
                                Text('${ardp.ceil()} %',style: tstyle,),
                              ],
                            ),
                          )),
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('ECLAT',style: tstyle,),
                                const Spacer(),
                                Checkbox(checked: parAve, onChanged: (s){
                                  if(s==true){
                                    parAve=s!;
                                    parAvc=false;
                                    parAvf=false;
                                  }
                                  else if(s==false){
                                    parAve=false;
                                  }
                                  setState(() {

                                  });
                                })
                              ],
                            ),
                          )),
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('ECLAT',style: tstyle,),
                                const Spacer(),

                                Checkbox(checked: parAre, onChanged: (s){
                                  if(s==true){
                                    parAre=s!;
                                    parArf=false;
                                    parArc=false;
                                  }
                                  else if(s==false){
                                    parAre=false;
                                  }
                                  setState(() {

                                  });
                                })
                              ],
                            ),
                          )),
                          const TableCell(child: SizedBox(),),
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('ARD',style: tstyle,),
                                const Spacer(),
                                Checkbox(checked: feuARD, onChanged: (s){
                                  feuARD=s??false;
                                  setState(() {

                                  });
                                })
                              ],
                            ),
                          )),
                        ]
                    ),
                    TableRow(
                        children: [
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('ARG',style: tstyle,),
                                smallSpace,
                                smallSpace,
                                smallSpace,
                                SizedBox(
                                  width: 5.w,
                                  child: Slider(value: argp, onChanged: (s){
                                    argp=s;
                                    setState(() {

                                    });
                                  },
                                    divisions: 100,
                                    label: 'ARG',
                                  ),
                                ),
                                smallSpace,
                                smallSpace,
                                smallSpace,
                                Text('${ardp.ceil()} %',style: tstyle,),
                              ],
                            ),
                          )),
                          const TableCell(child: SizedBox()),
                          const TableCell(child: SizedBox()),
                          const TableCell(child: SizedBox(),),
                          TableCell(child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                Text('ARG',style: tstyle,),
                                const Spacer(),
                                Checkbox(checked: feuARG, onChanged: (s){
                                  feuARG=s??false;
                                  setState(() {

                                  });
                                })
                              ],
                            ),
                          )),
                        ]
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: 35.w,
                height: 30.h,
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Positioned.fill(child: Image.asset('assets/images/car.webp')),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 80.w,
          height: 30.h,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ToggleSwitch(
                    content: Text('Vidange moteur',style: tstyle,),
                    checked: r1,
                    onChanged: (s){
                    setState(() {
                      r1=s;
                    });
                  },

                  ),
                  ToggleSwitch(
                    content: Text('Vidange boite',style: tstyle,),
                    checked: r2,
                    onChanged: (s){
                    setState(() {
                      r2=s;
                    });
                  },

                  ),
                  ToggleSwitch(
                    content: Text('Vidange pont AV AR',style: tstyle,),
                    checked: r3,
                    onChanged: (s){
                    setState(() {
                      r3=s;
                    });
                  },

                  ),
                  ToggleSwitch(
                    content: Text('Filtre à air',style: tstyle,),
                    checked: r4,
                    onChanged: (s){
                    setState(() {
                      r4=s;
                    });
                  },

                  ),
                  ToggleSwitch(
                    content: Text('Filtre à huile',style: tstyle,),
                    checked: r5,
                    onChanged: (s){
                    setState(() {
                      r5=s;
                    });
                  },

                  ),
                  ToggleSwitch(
                    content: Text('Filtre à carburant',style: tstyle,),
                    checked: r6,
                    onChanged: (s){
                    setState(() {
                      r6=s;
                    });
                  },

                  ),
                ],
              ),
              smallSpace,
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ToggleSwitch(
                    content: Text("Filtre d'habitacle",style: tstyle,),
                    checked: r7,
                    onChanged: (s){
                      setState(() {
                        r7=s;
                      });
                    },

                  ),
                  ToggleSwitch(
                    content: Text('Liquide de frein',style: tstyle,),
                    checked: r8,
                    onChanged: (s){
                      setState(() {
                        r8=s;
                      });
                    },

                  ),
                  ToggleSwitch(
                    content: Text('Liquide de refroidissement',style: tstyle,),
                    checked: r9,
                    onChanged: (s){
                      setState(() {
                        r9=s;
                      });
                    },

                  ),
                  ToggleSwitch(
                    content: Text('Equilibrage roues',style: tstyle,),
                    checked: r10,
                    onChanged: (s){
                      setState(() {
                        r10=s;
                      });
                    },

                  ),
                  ToggleSwitch(
                    content: Text('Pneus AV',style: tstyle,),
                    checked: r11,
                    onChanged: (s){
                      setState(() {
                        r11=s;
                      });
                    },

                  ),
                  ToggleSwitch(
                    content: Text('Pneus AR',style: tstyle,),
                    checked: r12,
                    onChanged: (s){
                      setState(() {
                        r12=s;
                      });
                    },

                  ),
                ],
              ),
              smallSpace,
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ToggleSwitch(
                    content: Text('Controle niveaux',style: tstyle,),
                    checked: r13,
                    onChanged: (s){
                      setState(() {
                        r13=s;
                      });
                    },

                  ),
                  ToggleSwitch(
                    content: Text('Entretien climatisation',style: tstyle,),
                    checked: r14,
                    onChanged: (s){
                      setState(() {
                        r14=s;
                      });
                    },

                  ),
                  ToggleSwitch(
                    content: Text('Balais essuie-glace',style: tstyle,),
                    checked: r15,
                    onChanged: (s){
                      setState(() {
                        r15=s;
                      });
                    },

                  ),
                  ToggleSwitch(
                    content: Text('Eclairage',style: tstyle,),
                    checked: r16,
                    onChanged: (s){
                      setState(() {
                        r16=s;
                      });
                    },

                  ),
                  ToggleSwitch(
                    content: Text('OBD',style: tstyle,),
                    checked: r17,
                    onChanged: (s){
                      setState(() {
                        r17=s;
                      });
                    },

                  ),
                  ToggleSwitch(
                    content: Text('Bougies',style: tstyle,),
                    checked: r18,
                    onChanged: (s){
                      setState(() {
                        r18=s;
                      });
                    },

                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
