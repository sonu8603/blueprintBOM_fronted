class Spool {
  String drawingNo;
  String spoolMarkNo;
  String lineNo;
  String size;
  String material;
  String nosOff;
  String weldType;
  String rt;
  String pt;
  String dispatchStatus;
  String remarks;

  Spool({
    required this.drawingNo,
    required this.spoolMarkNo,
    required this.lineNo,
    required this.size,
    required this.material,
    this.nosOff = '1',
    this.weldType = 'BUTT+FILLET',
    this.rt = '',
    this.pt = '',
    this.dispatchStatus = 'Pending',
    this.remarks = '',
  });

  factory Spool.fromJson(Map<String, dynamic> json) => Spool(
    drawingNo: json['drawing_no']?.toString() ?? '',
    spoolMarkNo: json['spool_mark']?.toString() ?? json['spool_mark_no']?.toString() ?? '',
    lineNo: json['line_no']?.toString() ?? '',
    size: json['size']?.toString() ?? '',
    material: json['material']?.toString() ?? '',
    nosOff: json['nos_off']?.toString() ?? '1',
    weldType: json['weld_type']?.toString() ?? 'BUTT+FILLET',
    rt: json['rt']?.toString() ?? '',
    pt: json['pt']?.toString() ?? '',
    dispatchStatus: json['dispatch_status']?.toString() ?? 'Pending',
    remarks: json['remarks']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'drawing_no': drawingNo,
    'spool_mark_no': spoolMarkNo,
    'line_no': lineNo,
    'size': size,
    'material': material,
    'nos_off': nosOff,
    'weld_type': weldType,
    'rt': rt,
    'pt': pt,
    'dispatch_status': dispatchStatus,
    'remarks': remarks,
  };
}