class Setting {
  final String key;
  final String value;

  Setting({required this.key, required this.value});

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'value': value};
}
