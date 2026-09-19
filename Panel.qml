import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "cittadhammo.languagetool"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null
  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property bool running: service ? service.running === true : false
  readonly property string action: service ? String(service.pendingAction || "") : ""
  readonly property string stateText: {
    if (!service) return "Checking…"
    if (action === "start") return "Starting…"
    if (action === "stop") return "Stopping…"
    if (service.lastError !== "") return service.lastError
    return running ? "Running on port " + service.port : "Stopped"
  }
  readonly property string stateColor: {
    if (!service) return Qt.darker(root.foreground, 1.45)
    if (action !== "") return Color.accent
    return running ? root.foreground : Qt.darker(root.foreground, 1.45)
  }
  readonly property string toggleLabel: {
    if (action === "start") return "Starting…"
    if (action === "stop") return "Stopping…"
    return running ? "Turn off" : "Turn on"
  }
  readonly property string languageText: {
    if (!service) return "Loading…"
    var parts = []
    if (service.en === true) parts.push("English")
    if (service.fr === true) parts.push("French")
    if (parts.length > 0 && service.languageCount > parts.length)
      return parts.join(", ") + " + " + (service.languageCount - parts.length) + " more"
    if (parts.length > 0) return parts.join(", ")
    if (running) return "No language data loaded"
    return "Not loaded"
  }
  readonly property string pidText: {
    if (!service) return "—"
    if (!running) return "—"
    var text = service.pid ? "PID " + service.pid : "external process"
    if (service.pid && service.startedViaPlugin) text += " · managed here"
    return text
  }

  function copyToClipboard(value) {
    var text = String(value || "")
    if (text === "") return
    Quickshell.execDetached(["bash", "-c", "printf %s " + Util.shellQuote(text) + " | wl-copy"])
  }

  onOpenedChanged: {
    if (opened && service && service.refresh) service.refresh()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(460))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onActivateRequested: if (root.service) root.service.setRunning(!root.running)
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        Row {
          width: parent.width
          spacing: Style.space(12)

          Text {
            text: "󰓆"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            width: parent.width - parent.spacing - Style.space(36)
            spacing: Style.space(2)
            Text {
              text: "LanguageTool"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }
            Text {
              text: "Grammar and spell checking server"
              color: Qt.darker(root.foreground, 1.45)
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }
        }

        PanelSeparator { foreground: root.foreground }

        Text {
          visible: root.service && root.service.lastError !== ""
          width: parent.width
          text: root.stateText
          wrapMode: Text.Wrap
          color: Color.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Column {
          width: parent.width
          spacing: Style.space(6)

          Row {
            width: parent.width
            spacing: Style.space(12)
            Text {
              text: "STATE"
              color: Qt.darker(root.foreground, 1.45)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1
              width: Style.space(110)
            }
            Text {
              text: root.stateText
              color: root.stateColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }
          }

          Row {
            width: parent.width
            spacing: Style.space(12)
            Text {
              text: "PORT"
              color: Qt.darker(root.foreground, 1.45)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1
              width: Style.space(110)
            }
            Row {
              spacing: Style.space(8)
              Text {
                text: running ? "http://localhost:" + service.port : "—"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                anchors.verticalCenter: parent.verticalCenter
              }
              Button {
                visible: running
                iconText: "󰅌"
                tooltipText: "Copy to clipboard"
                fontFamily: root.fontFamily
                foreground: root.foreground
                horizontalPadding: Style.space(5)
                verticalPadding: Style.space(2)
                iconSize: Style.font.bodySmall
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.copyToClipboard("http://localhost:" + service.port)
              }
            }
          }

          Row {
            width: parent.width
            spacing: Style.space(12)
            Text {
              text: "LANGUAGES"
              color: Qt.darker(root.foreground, 1.45)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1
              width: Style.space(110)
            }
            Text {
              text: root.languageText
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }
          }

          Row {
            width: parent.width
            spacing: Style.space(12)
            Text {
              text: "PROCESS"
              color: Qt.darker(root.foreground, 1.45)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1
              width: Style.space(110)
            }
            Text {
              text: root.pidText
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }
          }
        }

        Button {
          id: toggleButton
          width: content.width
          text: root.toggleLabel
          iconText: "󰄀"
          fontFamily: root.fontFamily
          foreground: root.foreground
          selected: root.running
          enabled: root.action === ""
          onClicked: if (root.service) root.service.setRunning(!root.running)
        }
      }
    }
  }
}