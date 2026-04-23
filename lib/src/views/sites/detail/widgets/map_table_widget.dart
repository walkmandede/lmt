import 'package:flutter/material.dart';
import 'package:lmt/src/models/site_detail_model.dart';

class MapTableWidget extends StatelessWidget {
  final SiteDetailModel site;

  const MapTableWidget({super.key, required this.site});

  // ✅ Reusable cell with fixed height
  Widget _cell(Widget child, {double height = 42}) {
    return SizedBox(
      height: height,
      child: Center(child: child),
    );
  }

  // ✅ Reusable row builder
  TableRow _row(List<Widget> children) {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.9 * 255).toInt()),
      ),
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final poles = site.poles ?? [];
    final baseFontSize = 18.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    /// TABLE
                    Expanded(
                      flex: 6,
                      child: Table(
                        border: TableBorder.all(
                          color: Colors.black.withAlpha((0.6 * 255).toInt()),
                        ),
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(4),
                          3: FlexColumnWidth(2),
                          4: FlexColumnWidth(3),
                        },
                        children: [
                          /// HEADER
                          TableRow(
                            children: [
                              _cell(
                                Text(
                                  'No',
                                  style: TextStyle(color: Colors.black, fontSize: baseFontSize),
                                ),
                                height: 45,
                              ),
                              _cell(
                                Text(
                                  'Outline',
                                  style: TextStyle(color: Colors.black, fontSize: baseFontSize),
                                ),
                                height: 45,
                              ),
                              _cell(
                                Text(
                                  'Description',
                                  style: TextStyle(color: Colors.black, fontSize: baseFontSize),
                                ),
                                height: 45,
                              ),
                              _cell(
                                Text(
                                  'Unit',
                                  style: TextStyle(color: Colors.black, fontSize: baseFontSize),
                                ),
                                height: 45,
                              ),
                              _cell(
                                Text(
                                  'Qty',
                                  style: TextStyle(color: Colors.black, fontSize: baseFontSize),
                                ),
                                height: 45,
                              ),
                            ],
                          ),

                          /// ROW 1
                          _row([
                            _cell(
                              Text(
                                '1',
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                            _cell(Container(height: 2, width: 20, color: Colors.blue)),
                            _cell(
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  'Drop Cable Length',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: baseFontSize),
                                ),
                              ),
                            ),
                            _cell(
                              Text(
                                'Meter',
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                            _cell(
                              Text(
                                site.dropCableLengthInMeter ?? '-',
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                          ]),

                          /// ROW 2
                          _row([
                            _cell(
                              Text(
                                '2',
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                            _cell(
                              SizedBox(
                                width: 25,
                                height: 25,
                                child: Card(
                                  elevation: 0,
                                  shape: const CircleBorder(),
                                  color: Colors.blue,
                                  child: Center(
                                    child: Container(
                                      height: 3,
                                      width: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _cell(
                              Text(
                                'Other Pole',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                            _cell(
                              Text(
                                'Pcs',
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                            _cell(
                              Text(
                                poles.where((p) => p.enumPoleType == EnumPoleType.other).length.toString(),
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                          ]),

                          /// ROW 3
                          _row([
                            _cell(
                              Text(
                                '3',
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                            _cell(
                              SizedBox(
                                width: 25,
                                height: 25,
                                child: Card(
                                  elevation: 0,
                                  shape: const CircleBorder(),
                                  color: Colors.red,
                                  child: Center(
                                    child: Container(
                                      height: 3,
                                      width: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _cell(
                              Text(
                                'EPC Pole',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                            _cell(
                              Text(
                                'Pcs',
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                            _cell(
                              Text(
                                poles.where((p) => p.enumPoleType == EnumPoleType.epc).length.toString(),
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                          ]),

                          /// ROW 4
                          _row([
                            _cell(
                              Text(
                                '4',
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                            _cell(
                              SizedBox(
                                width: 25,
                                height: 25,
                                child: Card(
                                  elevation: 0,
                                  shape: const CircleBorder(),
                                  color: Colors.green,
                                  child: Center(
                                    child: Container(
                                      height: 3,
                                      width: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _cell(
                              Text(
                                'MPT Pole',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                            _cell(
                              Text(
                                'Pcs',
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                            _cell(
                              Text(
                                poles.where((p) => p.enumPoleType == EnumPoleType.mpt).length.toString(),
                                style: TextStyle(fontSize: baseFontSize),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),

                    /// RIGHT SIDE BOX
                    const Expanded(flex: 1, child: SizedBox.shrink()),

                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(border: Border.all()),
                        child: Text(
                          'LSP Name: ${site.lspName ?? '-'}',
                          style: TextStyle(fontSize: baseFontSize),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
