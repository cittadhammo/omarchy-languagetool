import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property bool running: false
  property bool busy: false
  property string pendingAction: ""
  property int pid: 0
  property bool startedViaPlugin: false
  property bool en: false
  property bool fr: false
  property int languageCount: 0
  property string lastError: "Checking LanguageTool server…"
  property string _statusOutput: ""
  property string _statusError: ""
  property string _controlOutput: ""
  property string _controlError: ""
  readonly property int port: 8081
  readonly property string helperPath: String(Qt.resolvedUrl("languagetoolctl")).replace("file://", "")

  function parseStatus(raw, fallbackError) {
    try {
      var result = JSON.parse(raw)
      if (result.ok === true) {
        root.running = result.running === true
        root.pid = result.pid ? Number(result.pid) : 0
        root.startedViaPlugin = result.startedViaPlugin === true
        root.en = result.en === true
        root.fr = result.fr === true
        root.languageCount = Number(result.languageCount || 0)
        root.lastError = ""
      } else {
        root.lastError = String(result.error || fallbackError)
      }
    } catch (error) {
      root.running = false
      root.lastError = "Invalid response from languagetoolctl"
    }
  }

  function parseControl(raw, fallbackError) {
    try {
      var result = JSON.parse(raw)
      if (result.ok === true) {
        root.lastError = ""
      } else {
        root.lastError = String(result.error || fallbackError)
      }
    } catch (error) {
      root.lastError = fallbackError
    }
  }

  function refresh() {
    if (statusProcess.running) return
    _statusOutput = ""
    _statusError = ""
    statusProcess.command = [helperPath, "status"]
    statusProcess.running = true
  }

  function setRunning(wanted) {
    if (controlProcess.running || root.busy) return
    if (root.running === wanted && root.pendingAction === "") {
      root.refresh()
      return
    }
    root.busy = true
    root.pendingAction = wanted ? "start" : "stop"
    _controlOutput = ""
    _controlError = ""
    controlProcess.command = [helperPath, wanted ? "start" : "stop"]
    controlProcess.running = true
  }

  function notifyState(action) {
    var summary = action === "start" ? "Server started" : "Server stopped"
    var body = action === "start"
      ? "LanguageTool is running on http://localhost:" + root.port + " (English + French)"
      : "The LanguageTool server is no longer running."
    notifyProcess.command = ["notify-send", "-a", "LanguageTool", "-i", "utilities-terminal", summary, body]
    notifyProcess.running = true
  }

  Process {
    id: statusProcess
    running: false
    stdout: StdioCollector { id: statusStdout; waitForEnd: true; onStreamFinished: root._statusOutput = text }
    stderr: StdioCollector { id: statusStderr; waitForEnd: true; onStreamFinished: root._statusError = text }
    onExited: function(exitCode) {
      root.parseStatus(String(statusStdout.text || root._statusOutput || ""),
        String(statusStderr.text || root._statusError || "LanguageTool status check failed").trim())
    }
  }

  Process {
    id: controlProcess
    running: false
    stdout: StdioCollector { id: controlStdout; waitForEnd: true; onStreamFinished: root._controlOutput = text }
    stderr: StdioCollector { id: controlStderr; waitForEnd: true; onStreamFinished: root._controlError = text }
    onExited: function(exitCode) {
      var action = root.pendingAction
      root.parseControl(String(controlStdout.text || root._controlOutput || ""),
        String(controlStderr.text || root._controlError || "LanguageTool control failed").trim())
      root.busy = false
      root.pendingAction = ""
      root.refresh()
      if (exitCode === 0 && action !== "") root.notifyState(action)
    }
  }

  Process {
    id: notifyProcess
    running: false
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}