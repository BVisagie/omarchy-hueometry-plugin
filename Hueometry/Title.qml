import QtQuick
import "js/palette.mjs" as Palette

// "Hueometry", each letter tinted with an orb colour.
Row {
  id: root
  property real size: Theme.em * 4
  spacing: 0
  Repeater {
    model: "Hueometry".split("")
    Text {
      required property string modelData
      required property int index
      text: modelData
      color: Palette.orb(index % 6).light
      font.family: Theme.font
      font.pixelSize: root.size
      font.bold: true
      style: Text.Outline
      styleColor: Palette.orb(index % 6).dark
    }
  }
}
