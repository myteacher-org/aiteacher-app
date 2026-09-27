/// Reaction codes accepted by the backend's `emoji_reaction`/`player_reaction`
/// socket events, in display order. The server only ever sees/sends these
/// codes — never the emoji glyph — so it can be swapped for custom
/// sticker/animation art later without a contract change.
const battleReactionCodes = [
  'strong',
  'laugh',
  'cool',
  'shush',
  'evil',
  'thumbsup',
  'croissant',
];

const battleReactionEmojis = {
  'strong': '💪',
  'laugh': '😁',
  'cool': '😎',
  'shush': '🤫',
  'evil': '😈',
  'thumbsup': '👍',
  'croissant': '🥐',
};

String battleReactionEmojiFor(String code) => battleReactionEmojis[code] ?? '❔';
