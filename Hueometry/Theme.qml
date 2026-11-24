pragma Singleton
import QtQuick

// Colours, sizes and timings shared by the whole game. Game.qml sets the
// player's settings here; every animation reads its duration from here, so
// reduced motion reaches all of them.
QtObject {
  property bool reducedMotion: false
  property bool symbols: false
  property real uiScale: 1.0
  // the size text and buttons are measured in, from the window
  property real em: 18

  function ms(n) { return reducedMotion ? 0 : n }

  readonly property color ink: "#FBF4DF"
  readonly property color inkSoft: "#D9CFB2"
  readonly property color inkDark: "#1E2A1C"
  readonly property color leaf: "#2F5A2E"
  readonly property color leafDeep: "#16311B"
  readonly property color canopy: "#0D2014"
  readonly property color stone: "#8B8F78"
  readonly property color stoneLight: "#C4C2A4"
  readonly property color stoneDark: "#4A4C3C"
  readonly property color moss: "#6E9A3A"
  readonly property color gold: "#F2C14E"
  readonly property color glow: "#FFE7A0"
  // opaque, so the screen behind never shows through a card's text
  readonly property color card: "#142319"
  readonly property color cardEdge: "#5A7A4A"
  // Nunito (SIL Open Font License, LICENSE-OFL), bundled so the game looks
  // the same on every machine; the three styles register as one family, so
  // font.bold and font.italic pick the right file
  readonly property FontLoader regular: FontLoader { source: "fonts/Nunito-Regular.ttf" }
  readonly property FontLoader bold: FontLoader { source: "fonts/Nunito-Bold.ttf" }
  readonly property FontLoader italic: FontLoader { source: "fonts/Nunito-Italic.ttf" }
  readonly property string font: regular.status === FontLoader.Ready ? regular.font.family : "sans-serif"
}
