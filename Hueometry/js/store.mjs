import levels from "./levels.mjs";

// Progress and settings, as plain data, and how two copies of the progress
// combine. The standalone app and the shell plugin share one save folder;
// progress only ever grows (a level done stays done, a best only improves),
// so merging what is on disk with what is in memory before every write loses
// nothing, whichever copy writes last.

// Both save files carry this format version. A save without one is
// version 1. A save from a newer Hueometry is read as far as this one
// understands it, and never overwritten.
export const VERSION = 1;

export function newer(raw) {
  const v = parse(raw).version;
  return typeof v === "number" && v > VERSION;
}

// The text to write: this version's fields over whatever else the file on
// disk holds, so nothing this version does not know about is lost.
export function settingsText(diskRaw, s) {
  return JSON.stringify(Object.assign({}, parse(diskRaw), s, { version: VERSION }));
}

export function progressText(diskRaw, p) {
  const disk = parse(diskRaw);
  // inside records and the unfinished puzzle too
  const diskDone = disk.done && typeof disk.done === "object" ? disk.done : {};
  // entries this version does not read as records stay as they were
  const done = Object.assign({}, diskDone);
  for (const [k, v] of Object.entries(p.done)) {
    const old = diskDone[k];
    // the winning record gives the score; this file's own fields win over
    // fields carried in from the other host's file
    done[k] = old && typeof old === "object" ? Object.assign({}, v, old, { best: v.best, assisted: v.assisted }) : v;
  }
  const same = p.current && disk.current && typeof disk.current === "object" && disk.current.ref
    && disk.current.pack === p.current.pack && sameRef(disk.current.ref, p.current.ref);
  const current = same ? sameCurrent(disk.current, p.current) : p.current;
  return JSON.stringify(Object.assign({}, disk, p, { done, current, version: VERSION }));
}

// the same puzzle saved again: the game's own fields from the newest copy,
// and the destination's unknown fields kept, in its ref too
function sameCurrent(old, now) {
  const pick = (o, names) => {
    const out = {};
    for (const n of names) if (n in o) out[n] = o[n];
    return out;
  };
  const ref = Object.assign({}, now.ref, old.ref, pick(now.ref, NAMING[now.ref.kind] || []));
  return Object.assign({}, now, old, pick(now, ["moves", "assisted", "pack"]), { ref });
}

// The fields that name a puzzle, by kind.
const NAMING = { tutorial: ["kind", "index"], level: ["kind", "area", "index"], free: ["kind", "difficulty", "index"] };

// A puzzle's identity from its ref, or null when the ref is malformed.
function refId(r) {
  if (!r || typeof r !== "object" || !Number.isInteger(r.index)) return null;
  if (r.kind === "tutorial") return `tutorial/${r.index}`;
  if (r.kind === "level" && typeof r.area === "string") return `level/${r.area}/${r.index}`;
  if (r.kind === "free" && typeof r.difficulty === "string") return `free/${r.difficulty}/${r.index}`;
  return null;
}

// the same puzzle: only the fields that name a puzzle of its kind count
function sameRef(a, b) {
  const id = refId(a);
  return id !== null && id === refId(b);
}

export const SETTINGS = {
  music: 0.6,
  effects: 0.8,
  muted: false,
  reducedMotion: false,
  symbols: false,
  layout: "line",
  scale: 1.0,
};

const num = (x, lo, hi, d) => (typeof x === "number" && x >= lo && x <= hi ? x : d);

export function settings(raw) {
  const s = parse(raw);
  return {
    music: num(s.music, 0, 1, SETTINGS.music),
    effects: num(s.effects, 0, 1, SETTINGS.effects),
    muted: s.muted === true,
    reducedMotion: s.reducedMotion === true,
    symbols: s.symbols === true,
    layout: s.layout === "circle" ? "circle" : "line",
    scale: num(s.scale, 0.75, 1.5, SETTINGS.scale),
  };
}

// One setting changed: apply it to the settings on disk, so a change in one
// host never undoes a different change made in another.
export function withSetting(raw, key, value) {
  const next = settings(raw);
  next[key] = value;
  return settings(JSON.stringify(next));
}

function parse(raw) {
  if (typeof raw !== "string" || raw === "") return {};
  try {
    const v = JSON.parse(raw);
    return v && typeof v === "object" && !Array.isArray(v) ? v : {};
  } catch (e) {
    return {};
  }
}

// progress: { tutorial: bool, done: { key: { best, assisted } }, current,
//   currentAt }
// key: "area/index", "tutorial/index" or "free/difficulty/index".
// `assisted` is true when the best was reached with a hint.
// `current` is the puzzle left unfinished: { ref, moves: [[from, to]],
// assisted } (assisted: a hint was used in it).
export function progress(raw) {
  const p = parse(raw);
  const done = {};
  if (p.done && typeof p.done === "object") {
    for (const [k, v] of Object.entries(p.done)) {
      // fields a newer Hueometry added ride along through merges and saves
      if (v && Number.isInteger(v.best) && v.best > 0) done[k] = Object.assign({}, v, { best: v.best, assisted: v.assisted === true });
    }
  }
  // an unfinished puzzle from another pack names a different board: drop it
  const current = p.current && refId(p.current.ref) !== null && Array.isArray(p.current.moves) && p.current.pack === PACK
    ? Object.assign({}, p.current, { ref: p.current.ref, moves: p.current.moves, assisted: p.current.assisted === true, pack: PACK }) : null;
  // when `current` last changed (set or cleared), so the newest copy wins
  const currentAt = Number.isFinite(p.currentAt) ? p.currentAt : 0;
  return { tutorial: tutorialDone(done), done, current, currentAt };
}

// The tutorial is done when all three of its puzzles are.
function tutorialDone(done) {
  return [0, 1, 2].every((i) => !!done[key({ kind: "tutorial", index: i })]);
}

// Levels and free-play puzzles are named by their place in the level pack,
// so a record names the pack too: the pack id is a hash of its contents, so
// any change to a level or its order starts fresh records rather than
// crediting a best (or replaying moves) on a different board.
export const PACK = levels.pack;

export function key(ref) {
  if (ref.kind === "tutorial") return `${PACK}:tutorial/${ref.index}`;
  if (ref.kind === "level") return `${PACK}:${ref.area}/${ref.index}`;
  return `${PACK}:free/${ref.difficulty}/${ref.index}`;
}

// The better of two records: fewer moves, and unassisted beats assisted.
function better(a, b) {
  if (!a) return b;
  if (!b) return a;
  if (a.assisted !== b.assisted) return a.assisted ? b : a;
  return a.best <= b.best ? a : b;
}

// Records combine (the better of each); the unfinished puzzle is the one
// changed most recently, which may be "none" if it was finished elsewhere.
export function merge(disk, mine) {
  const done = Object.assign({}, disk.done);
  for (const [k, v] of Object.entries(mine.done)) done[k] = better(done[k], v);
  // newest wins; on a tie (saves without a time), a puzzle beats none
  const dt = mine.currentAt || 0, ot = disk.currentAt || 0;
  const newer = dt > ot ? mine : ot > dt ? disk : (mine.current ? mine : disk);
  return { tutorial: tutorialDone(done), done, current: newer.current, currentAt: newer.currentAt || 0 };
}

// A time for the next change that is later than any change already seen,
// even if the clock went back or two changes share a millisecond.
export function nextAt(p, now) {
  return Math.max(now, (p.currentAt || 0) + 1);
}

// The unfinished puzzle changed (at a time from nextAt).
export function setCurrent(p, current, at) {
  // the same puzzle keeps any fields a newer Hueometry stored with it
  const same = current && p.current && p.current.ref && sameRef(p.current.ref, current.ref);
  const next = current ? Object.assign({ pack: PACK }, current) : null;
  return Object.assign({}, p, { current: same ? sameCurrent(p.current, next) : next, currentAt: at });
}

// Records a solved puzzle. Answers { progress, record } where record says
// whether this beat the previous best ("first", "better", "same", "worse").
export function solved(p, ref, moveCount, assisted, at) {
  const k = key(ref);
  const before = p.done[k];
  const now = { best: moveCount, assisted: assisted === true };
  // a better result keeps any fields a newer Hueometry stored on the record
  const won = better(before, now) === now;
  const kept = won ? Object.assign({}, before, now) : before;
  let record = "first";
  if (before) record = won && (now.best < before.best || (before.assisted && !now.assisted)) ? "better" : now.best === before.best ? "same" : "worse";
  const done = Object.assign({}, p.done);
  done[k] = kept;
  // the unfinished puzzle is over only if it is this one: another puzzle
  // left unfinished (in either host) stays, with its own time
  const finished = !p.current || (p.current.ref && sameRef(p.current.ref, ref));
  const after = finished ? { current: null, currentAt: at || 0 } : {};
  return {
    progress: Object.assign({}, p, { tutorial: tutorialDone(done), done }, after),
    record, previous: before || null, assisted: now.assisted, best: kept,
  };
}

// An area opens once five levels of the one before it are done.
export const TO_OPEN = 5;

// how many of an area's puzzles are done ("tutorial" for the first steps)
export function doneIn(p, area, count) {
  let n = 0;
  for (let i = 0; i < count; i++) {
    if (p.done[key(area === "tutorial" ? { kind: "tutorial", index: i } : { kind: "level", area, index: i })]) n++;
  }
  return n;
}

export function areaOpen(p, areas, index, perArea) {
  if (index === 0) return true;
  return doneIn(p, areas[index - 1], perArea) >= TO_OPEN;
}
