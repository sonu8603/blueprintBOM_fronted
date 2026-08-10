class BomItem {
  String id;
  String drawingNo;
  String lineNo;
  String nd;
  double qty;
  String uom;
  String description;
  String category;
  String rev;
  String remarks;

  BomItem({
    required this.id,
    required this.drawingNo,
    required this.lineNo,
    required this.nd,
    required this.qty,
    required this.uom,
    required this.description,
    required this.category,
    this.rev = 'Rev 0',
    this.remarks = '',
  });

  factory BomItem.fromJson(Map<String, dynamic> json) {
    String desc = json['description']?.toString() ?? '';
    String rawUom = (json['uom']?.toString() ?? 'NOS').toUpperCase();
    return BomItem(
      id: json['id']?.toString() ?? '',
      drawingNo: json['drawing_no']?.toString() ?? '',
      lineNo: json['line_no']?.toString() ?? '',
      nd: json['nd']?.toString() ?? '',
      qty: double.tryParse(json['qty']?.toString() ?? '0') ?? 0.0,
      uom: rawUom == 'M' ? 'MTR' : rawUom,
      description: desc,
      category: json['category']?.toString() ?? classify(desc),
      rev: json['revision']?.toString() ?? json['rev']?.toString() ?? 'Rev 0',
      remarks: json['remarks']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'drawing_no': drawingNo,
    'line_no': lineNo,
    'nd': nd,
    'qty': qty,
    'uom': uom,
    'description': description,
    'category': category,
    'rev': rev,
    'remarks': remarks,
  };

  static String classify(String desc) {
    final d = desc.toUpperCase();
    if (RegExp(r'^PIPE\b').hasMatch(d)) return 'PIPE';
    if (RegExp(r'ELBOW|TEE|REDUCER|END CAP').hasMatch(d)) return 'FITTING';
    if (d.contains('FLANGE')) return 'FLANGE';
    if (d.contains('GASKET')) return 'GASKET';
    if (RegExp(r'STUD|BOLT|NUT|WASHER').hasMatch(d)) return 'BOLT';
    if (d.contains('VALVE')) return 'VALVE';
    if (RegExp(r'VICTAULIC|COUPLING').hasMatch(d)) return 'COUPLING';
    if (RegExp(r'BASE PLATE|SUPPORT|PAD|REINF').hasMatch(d)) return 'SUPPORT';
    return 'OTHER';
  }

  BomItem copyWith({
    String? id,
    String? drawingNo,
    String? lineNo,
    String? nd,
    double? qty,
    String? uom,
    String? description,
    String? category,
    String? rev,
    String? remarks,
  }) {
    return BomItem(
      id: id ?? this.id,
      drawingNo: drawingNo ?? this.drawingNo,
      lineNo: lineNo ?? this.lineNo,
      nd: nd ?? this.nd,
      qty: qty ?? this.qty,
      uom: uom ?? this.uom,
      description: description ?? this.description,
      category: category ?? this.category,
      rev: rev ?? this.rev,
      remarks: remarks ?? this.remarks,
    );
  }
}