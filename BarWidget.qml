import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "cittadhammo.languagetool"

  readonly property var ltService: bar && bar.shell && bar.shell.serviceFor
    ? bar.shell.serviceFor(moduleName) : null
  readonly property bool running: ltService ? ltService.running === true : false

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function injectPanel() {
    var panel = panelLoader.item
    if (!panel) return
    if ("bar" in panel) panel.bar = root.bar
    if ("settings" in panel) panel.settings = root.settings
    if ("anchorItem" in panel) panel.anchorItem = button
    if ("hostWidget" in panel) panel.hostWidget = root
    if ("service" in panel) panel.service = root.ltService
  }

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()
  onLtServiceChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰓆"
    dimmed: !root.running
    tooltipText: root.running
      ? "LanguageTool: running · left-click for details"
      : "LanguageTool: stopped · left-click for details"
    onPressed: function(button) {
      if (button === Qt.RightButton && root.running && root.ltService && root.ltService.refresh) root.ltService.refresh()
      else root.togglePanel()
    }
  }
}