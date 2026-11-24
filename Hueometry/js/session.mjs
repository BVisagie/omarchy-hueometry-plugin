// A puzzle in play, as the interface sees it: which puzzle, the engine's
// game, and which column has its top orb lifted. Every change to the game
// goes through rules.mjs; this file only remembers the player's selection and
// says what happened, so the interface can animate and play sounds.
//
// Qt's JavaScript engine has no object spread ({ ...x }): use Object.assign.

import * as R from "./rules.mjs";
import levels from "./levels.mjs";
import free from "./free.mjs";

export const AREAS = levels.areas.map((a) => a.id);
export const DIFFICULTIES = Object.keys(free.puzzles);

const moves = (pairs) => pairs.map(([from, to]) => ({ from, to }));

// The puzzle a reference names, or null:
//   { kind: "tutorial", index }
//   { kind: "level", area, index }       area is an id from AREAS
//   { kind: "free", difficulty, index }  difficulty is a key of DIFFICULTIES
export function puzzle(ref) {
  if (!ref || typeof ref !== "object") return null;
  if (ref.kind === "tutorial") {
    const t = levels.tutorial[ref.index];
    if (!t) return null;
    return { ref, colours: t.colours, cap: t.cap, columns: t.columns, solution: moves(t.solution), par: t.par, optimal: t.optimal };
  }
  let colours, cap, entry;
  if (ref.kind === "level") {
    const area = levels.areas.find((a) => a.id === ref.area);
    entry = area && area.levels[ref.index];
    if (!entry) return null;
    ({ colours, cap } = area);
  } else if (ref.kind === "free") {
    const set = DIFFICULTIES.indexOf(ref.difficulty) >= 0 ? free.puzzles[ref.difficulty] : null;
    entry = set && set.puzzles[ref.index];
    if (!entry) return null;
    ({ colours, cap } = set);
  } else {
    return null;
  }
  const p = R.generate(colours, cap, entry.seed);
  if (!p) return null;
  return { ref, colours, cap, columns: p.columns, solution: moves(entry.solution), par: entry.par, optimal: entry.optimal };
}

// Does a reference name a puzzle that exists? (Cheap: generates nothing.)
export function known(ref) {
  if (!ref || typeof ref !== "object" || !R.isIndex(ref.index)) return false;
  if (ref.kind === "tutorial") return ref.index < levels.tutorial.length;
  if (ref.kind === "level") {
    const area = levels.areas.find((a) => a.id === ref.area);
    return !!area && ref.index < area.levels.length;
  }
  if (ref.kind === "free") {
    // only the five sizes (a saved name like "constructor" is not one)
    return DIFFICULTIES.indexOf(ref.difficulty) >= 0 && ref.index < free.puzzles[ref.difficulty].puzzles.length;
  }
  return false;
}

export function start(p) {
  // undone: the moves taken back, latest last, for redo
  return { puzzle: p, game: R.newGame(p.colours, p.cap, p.columns), selected: -1, undone: [] };
}

// Resume a saved game: the same puzzle, with its moves replayed by the
// engine (illegal ones are dropped, as playing them would).
export function resume(p, playedMoves) {
  const s = start(p);
  return Object.assign({}, s, { game: R.replay(s.game, Array.isArray(playedMoves) ? playedMoves : []) });
}

export function view(s) {
  const v = R.view(s.game);
  return Object.assign({}, v, { selected: s.selected, targets: s.selected >= 0 ? R.targets(s.game, s.selected) : [] });
}

// The player touched a column. Answers { state, effect } where effect is
//   { kind: "lift", column }             a top orb rises
//   { kind: "drop", column }             it settles back (same column again)
//   { kind: "move", from, to, bead }     the engine accepted the move
//   { kind: "refuse", from, to, reason } the engine refused it
//   { kind: "empty", column }            nothing to lift there
//   { kind: "none" }
export function touch(s, column) {
  const cols = R.view(s.game).columns;
  if (!R.isIndex(column) || column >= cols.length || R.solved(s.game)) return { state: s, effect: { kind: "none" } };
  if (s.selected < 0) {
    // choosing only: nothing is lifted from an empty column, the same case
    // the engine refuses as EmptySource; no move is decided here
    if (cols[column].length === 0) return { state: s, effect: { kind: "empty", column } };
    return { state: Object.assign({}, s, { selected: column }), effect: { kind: "lift", column } };
  }
  if (s.selected === column) return { state: Object.assign({}, s, { selected: -1 }), effect: { kind: "drop", column } };
  const from = s.selected;
  const r = R.play(s.game, from, column);
  if (r.accepted) {
    // a new move forgets what was taken back
    return { state: Object.assign({}, s, { game: r.game, selected: -1, undone: [] }), effect: { kind: "move", from, to: column, bead: r.bead } };
  }
  // the orb stays lifted, so the player can choose another column
  return { state: s, effect: { kind: "refuse", from, to: column, reason: r.reason } };
}

export function cancel(s) {
  return s.selected < 0 ? s : Object.assign({}, s, { selected: -1 });
}

export function undo(s) {
  const moves = R.history(s.game);
  if (moves.length === 0) return Object.assign({}, s, { selected: -1 });
  const undone = (s.undone || []).concat([moves[moves.length - 1]]);
  return Object.assign({}, s, { game: R.undo(s.game), selected: -1, undone });
}

// Plays the move taken back last, again. The engine decides it as any move:
// answers { state, effect } like touch, with effect kind "none" when there
// is nothing to redo (or the engine refuses, which a taken-back move cannot).
export function redo(s) {
  const undone = s.undone || [];
  if (undone.length === 0 || R.solved(s.game)) return { state: s, effect: { kind: "none" } };
  const m = undone[undone.length - 1];
  const r = R.play(s.game, m.from, m.to);
  if (!r.accepted) return { state: Object.assign({}, s, { undone: [] }), effect: { kind: "none" } };
  return {
    state: Object.assign({}, s, { game: r.game, selected: -1, undone: undone.slice(0, -1) }),
    effect: { kind: "move", from: m.from, to: m.to, bead: r.bead },
  };
}

export function canRedo(s) {
  return !!s && (s.undone || []).length > 0;
}

export function restart(s) {
  return Object.assign({}, s, { game: R.restart(s.game), selected: -1, undone: [] });
}

export function hint(s) {
  return R.hint(s.game, s.puzzle.solution);
}

export function history(s) {
  return R.history(s.game);
}

export function puzzleCount(difficulty) {
  return DIFFICULTIES.indexOf(difficulty) >= 0 ? free.puzzles[difficulty].puzzles.length : 0;
}
