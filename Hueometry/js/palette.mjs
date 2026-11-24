// The six orb colours of the Lost Jungle Temple, and the carved symbol each
// one shows in symbols mode. Five come from the Okabe-Ito set, which stays
// distinct under the common kinds of colour blindness; a pearl moonstone
// replaces its sky blue, which was too close to its blue. tools/palette/check.py
// checks every pair under normal vision and three simulated deficiencies.

export const ORBS = [
  { name: "sun", base: "#F0E442", light: "#FFF9B8", dark: "#A8950E", symbol: "star" },
  { name: "moon", base: "#EDEEF2", light: "#FFFFFF", dark: "#7E8499", symbol: "circle" },
  { name: "jade", base: "#009E73", light: "#6FE6C0", dark: "#005A41", symbol: "leaf" },
  { name: "ember", base: "#D55E00", light: "#FFA866", dark: "#7A3500", symbol: "triangle" },
  { name: "lagoon", base: "#0072B2", light: "#5FB2EE", dark: "#003A5C", symbol: "square" },
  { name: "orchid", base: "#CC79A7", light: "#F7C8E2", dark: "#7E3C62", symbol: "diamond" },
];

export function orb(i) {
  return ORBS[((i % ORBS.length) + ORBS.length) % ORBS.length];
}
