class AlarmInfo {
  int? id;
  String? title;
  DateTime? alarmDateTime;
  int? isPending; // Change from bool? to int?
  int? gradientColorIndex;

  AlarmInfo({
    this.id,
    this.title,
    this.alarmDateTime,
    this.isPending,
    this.gradientColorIndex,
  });

  factory AlarmInfo.fromMap(Map<String, dynamic> json) => AlarmInfo(
    id: json["id"],
    title: json["title"],
    alarmDateTime: DateTime.parse(json["alarmDateTime"]),
    isPending: json["isPending"], // Now accepts int directly
    gradientColorIndex: json["gradientColorIndex"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "title": title,
    "alarmDateTime": alarmDateTime!.toIso8601String(),
    "isPending": isPending,
    "gradientColorIndex": gradientColorIndex,
  };

  // Helper method to convert int to bool for UI usage
  bool get isActive => isPending == 1;
}