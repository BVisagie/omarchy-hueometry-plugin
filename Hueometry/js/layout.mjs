// Board layouts: where each column stands, and the order the keyboard walks
// them. A layout knows only how many columns there are and how much room it
// has; it never sees beads and never decides whether a move is legal, so
// changing it cannot change the game (brief, section 4).
//
// place(pattern, n, width, height, cap) answers
//   { columns: [{ x, y, w, h, angle }], order, unit }
// For each column, (x, y) is the middle of its base, w and h its width and
// length, and angle the direction it grows in, in degrees clockwise from
// straight up (the line layout's 0; the circle's spokes point outwards).
// Beads stack from the base along that direction, one `unit` apart. `order`
// lists the columns in the order the keyboard visits them.

export const PATTERNS = ["line", "circle"];

const PILLAR_W = 1.25; // in bead units
const LIFT = 1.7; // room beyond the top for a lifted bead

function length(cap) {
  return cap + 0.9;
}

function line(n, width, height, cap) {
  const gap = 0.6;
  const unitsW = n * PILLAR_W + (n - 1) * gap;
  const unitsH = length(cap) + LIFT;
  const unit = Math.min(width / (unitsW + 1.2), height / (unitsH + 0.8));
  const left = (width - unitsW * unit) / 2;
  const base = (height + unitsH * unit) / 2;
  const columns = [];
  for (let i = 0; i < n; i++) {
    columns.push({ x: left + (i * (PILLAR_W + gap) + PILLAR_W / 2) * unit, y: base, w: PILLAR_W * unit, h: length(cap) * unit, angle: 0 });
  }
  return { columns, order: [...Array(n).keys()], unit };
}

// Spokes around a medallion: the first points straight up and the rest
// follow clockwise. The inner circle is wide enough for the spokes' bases to
// sit side by side.
function circle(n, width, height, cap) {
  const inner = Math.max((n * (PILLAR_W + 0.45)) / (2 * Math.PI), 1.3);
  const reach = inner + length(cap) + LIFT;
  const unit = Math.min(width, height) / (2 * reach + 0.6);
  const cx = width / 2;
  const cy = height / 2;
  const columns = [];
  for (let i = 0; i < n; i++) {
    const angle = (360 * i) / n;
    const a = (angle * Math.PI) / 180;
    columns.push({
      x: cx + Math.sin(a) * inner * unit,
      y: cy - Math.cos(a) * inner * unit,
      w: PILLAR_W * unit,
      h: length(cap) * unit,
      angle,
    });
  }
  return { columns, order: [...Array(n).keys()], unit, inner: inner * unit, centre: { x: cx, y: cy } };
}

export function place(pattern, n, width, height, cap) {
  if (!(n > 0) || !(width > 0) || !(height > 0) || !(cap > 0)) return { columns: [], order: [], unit: 0 };
  return pattern === "circle" ? circle(n, width, height, cap) : line(n, width, height, cap);
}

// The point `along` units from a column's base, along its direction.
export function along(c, unitsAlong, unit) {
  const a = (c.angle * Math.PI) / 180;
  return { x: c.x + Math.sin(a) * unitsAlong * unit, y: c.y - Math.cos(a) * unitsAlong * unit };
}

// Where bead `k` (0 at the base) of a column sits, and where a lifted bead
// hovers.
export function beadAt(c, k, unit) {
  return along(c, 0.45 + 0.5 + k, unit);
}

export function liftedAt(c, cap, unit) {
  return along(c, length(cap) + 0.85, unit);
}

// The next column in keyboard order from `current`, `by` places on
// (wrapping): the same for every layout, so play feels the same everywhere.
export function step(order, current, by) {
  if (order.length === 0) return -1;
  const at = order.indexOf(current);
  const from = at < 0 ? 0 : at;
  return order[(((from + by) % order.length) + order.length) % order.length];
}

// The column under a point, if any: a generous box around each pillar and
// the space above it, measured in the pillar's own direction, so small hands
// do not miss.
export function hit(columns, x, y, unit) {
  let best = -1;
  let bestD = Infinity;
  for (let i = 0; i < columns.length; i++) {
    const c = columns[i];
    const a = (c.angle * Math.PI) / 180;
    const dx = x - c.x;
    const dy = y - c.y;
    const across = dx * Math.cos(a) + dy * Math.sin(a);
    const up = dx * Math.sin(a) - dy * Math.cos(a);
    const halfW = Math.max(c.w * 0.75, 22);
    if (Math.abs(across) > halfW || up < -0.5 * unit || up > c.h + LIFT * unit) continue;
    if (Math.abs(across) < bestD) {
      bestD = Math.abs(across);
      best = i;
    }
  }
  return best;
}
