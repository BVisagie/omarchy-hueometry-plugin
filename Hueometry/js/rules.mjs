// The one door between the interface and the Bend rules engine.
//
// Every game state the interface shows comes from here, and every change to
// it goes through engine.mjs. This file only converts between JavaScript
// arrays and Bend values; it decides no rule itself.
//
// Boards are arrays of columns; a column is an array of colour numbers from
// the TOP bead down, as in the engine. A game is an opaque engine value:
// keep it, pass it back, and read it with view().

import * as E from "./engine.mjs";

const NIL = { $: "Nil" };

export function list(items) {
  let l = NIL;
  for (let i = items.length - 1; i >= 0; i--) l = { $: "Con", head: items[i], tail: l };
  return l;
}

export function array(l) {
  const out = [];
  while (l.$ === "Con") {
    out.push(l.head);
    l = l.tail;
  }
  return out;
}

export function toBoard(columns) {
  return list(columns.map(list));
}

export function fromBoard(b) {
  return array(b).map(array);
}

// A column number the engine can take: a whole number from 0 up. Anything
// else (negative, fractional, huge, not a number) names no column.
export function isIndex(n) {
  return Number.isSafeInteger(n) && n >= 0 && n < 2 ** 31;
}

// The largest puzzles the game supports (the biggest level is 6 colours of
// 10). The engine has no limit, but bigger boards cost time no player should
// wait for, so the adapter refuses them.
export const MAX_COLOURS = 8;
export const MAX_CAP = 12;
const sizeOk = (colours, cap) => isIndex(colours) && isIndex(cap) && colours <= MAX_COLOURS && cap <= MAX_CAP;

const REASONS = {
  NoSuchColumn: "no-such-column",
  SameColumn: "same-column",
  EmptySource: "empty-source",
  FullTarget: "full-target",
};

// Is this a valid puzzle: colours + 1 columns of at most cap beads, exactly
// cap beads of each colour 0 .. colours - 1, and nothing else?
export function valid(colours, cap, columns) {
  if (!sizeOk(colours, cap) || !Array.isArray(columns)) return false;
  if (columns.length !== colours + 1) return false;
  for (let i = 0; i < columns.length; i++) {
    const c = columns[i];
    if (!Array.isArray(c) || c.length > cap) return false;
    for (let j = 0; j < c.length; j++) if (!isIndex(c[j]) || c[j] >= colours) return false;
  }
  return E.valid(colours, cap, toBoard(columns)) === true;
}

// A new game from a valid board (columns top first). Throws on an invalid
// one, so a damaged save can never start a game.
export function newGame(colours, cap, columns) {
  if (!valid(colours, cap, columns)) throw new RangeError("hueometry: not a valid board");
  return E.new_game(colours, cap, toBoard(columns));
}

// A move is { from, to } or, as the level pack stores it, [from, to].
const moveOf = (m) => (Array.isArray(m) ? { from: m[0], to: m[1] } : m);
const toMoves = (ms) => list(ms.map(moveOf).filter((m) => m && isIndex(m.from) && isIndex(m.to))
  .map((m) => ({ $: "Mv", from: m.from, to: m.to })));
const fromMoves = (l) => array(l).map((m) => ({ from: m.from, to: m.to }));

// A puzzle from a seed (a 32-bit number): { columns, solution } where the
// solution (oldest move first) is valid but usually long; or null.
export function generate(colours, cap, seed) {
  // one colour, or columns of one bead, can never be mixed: answer at once
  if (!sizeOk(colours, cap) || colours < 2 || cap < 2 || !Number.isInteger(seed)) return null;
  const out = E.generate(colours, cap, seed >>> 0);
  if (out.$ !== "Some") return null;
  return { columns: fromBoard(out.value.board), solution: fromMoves(out.value.cert) };
}

// A hint along `solution` (moves as { from, to } or [from, to], oldest
// first, from the game's first board):
// { kind: "play", from, to }, { kind: "back", steps } (undo that many moves
// to return to the solution), { kind: "solved" } or { kind: "none" }.
export function hint(game, solution) {
  if (!Array.isArray(solution)) return { kind: "none" };
  const h = E.hint(game, toMoves(solution));
  switch (h.$) {
    case "Play": return { kind: "play", from: h.move.from, to: h.move.to };
    case "Back": return { kind: "back", steps: h.steps };
    case "Solved": return { kind: "solved" };
    default: return { kind: "none" };
  }
}

// Asks the engine to move the top bead of column `from` onto column `to`.
// Answers { accepted, game, bead, reason }: bead is the colour moved; when
// refused, the game is unchanged and bead is null.
export function play(game, from, to) {
  if (!isIndex(from) || !isIndex(to)) return { accepted: false, game, bead: null, reason: "no-such-column" };
  const out = E.play(game, from, to);
  if (out.$ === "Accepted") return { accepted: true, game: out.game, bead: out.bead, reason: null };
  return { accepted: false, game, bead: null, reason: REASONS[out.reason.$] };
}

export function undo(game) {
  return E.undo(game);
}

export function restart(game) {
  return E.restart(game);
}

export function solved(game) {
  return E.solved(game) === true;
}

export function moves(game) {
  return E.moves(game);
}

export function targets(game, column) {
  if (!isIndex(column)) return [];
  return array(E.targets(game, column));
}

// The moves played so far, oldest first, as { from, to }.
export function history(game) {
  return array(game.history).reverse().map((m) => ({ from: m.from, to: m.to }));
}

// Replays moves ({ from, to } or [from, to], oldest first) from the game's
// current board,
// exactly as calling play() for each would: a move naming no column is
// refused like any other illegal move.
export function replay(game, moveList) {
  return E.replay(game, toMoves(moveList));
}

// Everything the interface needs to draw a game.
export function view(game) {
  return {
    colours: game.colours,
    cap: game.cap,
    columns: fromBoard(game.board),
    start: fromBoard(game.start),
    moves: moves(game),
    solved: solved(game),
    // for each column: one colour and full (the engine decides)
    complete: array(E.complete(game)),
  };
}
