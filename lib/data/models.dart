/// Para quem foi a boa ação. Alimenta a retrospectiva ("18 foram para a família...").
enum ActionTarget {
  familia('Família', '🏡'),
  amigos('Amigos', '🤝'),
  desconhecidos('Desconhecidos', '🌍'),
  animais('Animais', '🐾'),
  voce('Você mesmo', '🌱'),
  planeta('Planeta', '🌳'),
  comunidade('Comunidade', '🏘️'),
  colegas('Colegas', '💼');

  const ActionTarget(this.label, this.emoji);
  final String label;
  final String emoji;

  static ActionTarget byName(String? name) {
    for (final t in values) {
      if (t.name == name) return t;
    }
    return ActionTarget.desconhecidos;
  }
}

class GoodAction {
  const GoodAction(this.id, this.text, this.target);
  final String id;
  final String text;
  final ActionTarget target;
}

/// Boa ação que a pessoa fez por conta própria (fora do catálogo).
class OwnAction {
  const OwnAction({required this.text, required this.target});

  final String text;
  final ActionTarget target;

  Map<String, dynamic> toJson() => {'text': text, 'to': target.name};

  factory OwnAction.fromJson(Map<String, dynamic> j) =>
      OwnAction(text: j['text'] as String? ?? '', target: ActionTarget.byName(j['to'] as String?));
}

/// Tema de um bom momento. O usuário pode escolher; se não escolher,
/// tentamos adivinhar por palavras-chave (ver tags.dart).
enum MomentTag {
  pessoas('Pessoas', '❤️'),
  familia('Família', '🏡'),
  pets('Pets', '🐶'),
  natureza('Natureza', '🌿'),
  comida('Comida e café', '☕'),
  trabalho('Trabalho', '💼'),
  conquista('Conquista', '🏆'),
  lazer('Lazer', '🎈'),
  saude('Saúde', '💪'),
  engracado('Engraçado', '😂'),
  viagem('Viagem', '✈️'),
  aprendizado('Aprendizado', '📚');

  const MomentTag(this.label, this.emoji);
  final String label;
  final String emoji;

  static MomentTag? byName(String? name) {
    for (final t in values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

class Moment {
  Moment({required this.text, this.tag, this.favorite = false});

  final String text;
  final MomentTag? tag;
  final bool favorite;

  Moment copyWith({String? text, MomentTag? tag, bool clearTag = false, bool? favorite}) => Moment(
        text: text ?? this.text,
        tag: clearTag ? null : (tag ?? this.tag),
        favorite: favorite ?? this.favorite,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        if (tag != null) 'tag': tag!.name,
        if (favorite) 'fav': true,
      };

  factory Moment.fromJson(Map<String, dynamic> j) => Moment(
        text: j['text'] as String? ?? '',
        tag: MomentTag.byName(j['tag'] as String?),
        favorite: j['fav'] as bool? ?? false,
      );
}

/// Tudo o que aconteceu em um dia. A chave é 'yyyy-MM-dd'.
class DayEntry {
  DayEntry({
    required this.day,
    this.actionId,
    this.rerolls = 0,
    this.actionDone = false,
    this.actionNote,
    List<OwnAction>? ownActions,
    List<Moment>? moments,
  })  : ownActions = ownActions ?? [],
        moments = moments ?? [];

  final String day;
  String? actionId;
  int rerolls;
  bool actionDone;
  String? actionNote;

  /// Boas ações extras registradas pela própria pessoa.
  List<OwnAction> ownActions;
  List<Moment> moments;

  static const maxMoments = 3;

  /// Fez algum bem no dia: a sugestão ou uma ação própria.
  bool get didGood => actionDone || ownActions.isNotEmpty;
  int get goodCount => (actionDone ? 1 : 0) + ownActions.length;
  bool get hasAnything => didGood || moments.isNotEmpty;
  bool get momentsComplete => moments.length >= maxMoments;

  /// 0..4 — usado para colorir o calendário.
  int get intensity => (didGood ? 1 : 0) + moments.length.clamp(0, 3);

  Map<String, dynamic> toJson() => {
        if (actionId != null) 'a': actionId,
        if (rerolls > 0) 'r': rerolls,
        if (actionDone) 'done': true,
        if (actionNote != null && actionNote!.isNotEmpty) 'note': actionNote,
        if (ownActions.isNotEmpty) 'own': ownActions.map((a) => a.toJson()).toList(),
        if (moments.isNotEmpty) 'm': moments.map((m) => m.toJson()).toList(),
      };

  factory DayEntry.fromJson(String day, Map<String, dynamic> j) => DayEntry(
        day: day,
        actionId: j['a'] as String?,
        rerolls: j['r'] as int? ?? 0,
        actionDone: j['done'] as bool? ?? false,
        actionNote: j['note'] as String?,
        ownActions: (j['own'] as List? ?? [])
            .map((e) => OwnAction.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        moments: (j['m'] as List? ?? [])
            .map((e) => Moment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class AppSettings {
  AppSettings({
    this.name = '',
    this.onboarded = false,
    required this.firstDay,
    this.remindersOn = true,
    this.actionReminder = true,
    this.actionMinutes = 8 * 60 + 30,
    this.momentsReminder = true,
    this.momentsMinutes = 21 * 60,
    this.installTipDismissed = false,
  });

  String name;
  bool onboarded;

  /// Primeiro dia de uso. Dias anteriores não contam como "não feitos".
  String firstDay;

  bool remindersOn;
  bool actionReminder;

  /// Minutos desde a meia-noite.
  int actionMinutes;
  bool momentsReminder;
  int momentsMinutes;

  /// Versão web: a pessoa dispensou a dica de "adicionar à tela inicial".
  bool installTipDismissed;

  Map<String, dynamic> toJson() => {
        'name': name,
        'onboarded': onboarded,
        'firstDay': firstDay,
        'remindersOn': remindersOn,
        'actionReminder': actionReminder,
        'actionMinutes': actionMinutes,
        'momentsReminder': momentsReminder,
        'momentsMinutes': momentsMinutes,
        'installTipDismissed': installTipDismissed,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j, String fallbackFirstDay) => AppSettings(
        name: j['name'] as String? ?? '',
        onboarded: j['onboarded'] as bool? ?? false,
        firstDay: j['firstDay'] as String? ?? fallbackFirstDay,
        remindersOn: j['remindersOn'] as bool? ?? true,
        actionReminder: j['actionReminder'] as bool? ?? true,
        actionMinutes: j['actionMinutes'] as int? ?? 8 * 60 + 30,
        momentsReminder: j['momentsReminder'] as bool? ?? true,
        momentsMinutes: j['momentsMinutes'] as int? ?? 21 * 60,
        installTipDismissed: j['installTipDismissed'] as bool? ?? false,
      );
}
