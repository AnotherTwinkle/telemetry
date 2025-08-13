class AppConfig {
  final String? pairedNumber;
  final String? pairedAlias;
  final String? passkey;
  final bool autoDeleteSms;
  final bool showDataContentInChat;

  AppConfig({
    this.pairedNumber,
    this.pairedAlias,
    this.passkey,
    this.autoDeleteSms = false,
    this.showDataContentInChat = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'pairedNumber': pairedNumber,
      'pairedAlias' : pairedAlias,
      'passkey': passkey,
      'autoDeleteSms': autoDeleteSms ? 1 : 0,
      'showDataContentInChat' : showDataContentInChat ? 1 : 0,
    };
  }

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      pairedNumber: map['pairedNumber'],
      pairedAlias : map['pairedAlias'],
      passkey: map['passkey'],
      autoDeleteSms: map['autoDeleteSms'] == 1,
      showDataContentInChat : map['showDataContentInChat'] == 1,
    );
  }

  AppConfig copyWith({
    String? pairedNumber,
    String? pairedAlias,
    String? passkey,
    bool? autoDeleteSms,
    bool? showDataContentInChat,
  }) {
    return AppConfig(
      pairedNumber: pairedNumber ?? this.pairedNumber,
      pairedAlias: pairedAlias ?? this.pairedAlias,
      passkey: passkey ?? this.passkey,
      autoDeleteSms: autoDeleteSms ?? this.autoDeleteSms,
      showDataContentInChat : showDataContentInChat ?? this.showDataContentInChat,
    );
  }
} 