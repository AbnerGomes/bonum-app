import 'models.dart';

/// Palavras-chave para adivinhar o tema de um momento quando o usuário
/// não escolhe nenhum. Simples de propósito: comparação por radical.
const _keywords = <MomentTag, List<String>>{
  MomentTag.pets: ['cachorr', 'gat', 'pet', 'cão', 'cao', 'dog', 'filhote', 'passarinh'],
  MomentTag.comida: ['café', 'cafe', 'almoç', 'almoc', 'jantar', 'pizza', 'comi', 'bolo', 'sorvete', 'churrasco', 'cerveja', 'vinho', 'lanche', 'receita'],
  MomentTag.familia: ['mãe', 'mae', 'pai', 'filh', 'irmã', 'irma', 'irmão', 'irmao', 'avó', 'avo', 'vô', 'tia', 'tio', 'primo', 'prima', 'esposa', 'marido', 'família', 'familia'],
  MomentTag.pessoas: ['amig', 'conversa', 'abraço', 'abraco', 'encontr', 'visita', 'namor'],
  MomentTag.natureza: ['sol', 'chuva', 'praia', 'mar', 'parque', 'trilha', 'flor', 'planta', 'pôr do sol', 'por do sol', 'céu', 'ceu', 'lua'],
  MomentTag.trabalho: ['trabalho', 'reunião', 'reuniao', 'projeto', 'cliente', 'chefe', 'equipe', 'entrega'],
  MomentTag.conquista: ['consegui', 'terminei', 'passei', 'aprovad', 'conquist', 'finalmente', 'resolvi'],
  MomentTag.lazer: ['filme', 'série', 'serie', 'jogo', 'música', 'musica', 'show', 'livro', 'li ', 'festa', 'passeio'],
  MomentTag.saude: ['treino', 'academia', 'corri', 'corrida', 'caminh', 'dormi bem', 'yoga', 'pedal', 'bike'],
  MomentTag.engracado: ['ri ', 'rimos', 'risada', 'engraçad', 'engracad', 'piada', 'kkk', 'haha'],
  MomentTag.viagem: ['viag', 'aeroporto', 'hotel', 'férias', 'ferias', 'estrada', 'voo'],
  MomentTag.aprendizado: ['aprendi', 'curso', 'estudei', 'descobri', 'aula'],
};

MomentTag? guessTag(String text) {
  final t = ' ${text.toLowerCase()} ';
  for (final entry in _keywords.entries) {
    if (entry.value.any(t.contains)) return entry.key;
  }
  return null;
}

/// Tema efetivo: o escolhido pelo usuário ou o adivinhado.
MomentTag? effectiveTag(Moment m) => m.tag ?? guessTag(m.text);
