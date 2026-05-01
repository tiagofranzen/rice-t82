import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window
    property var notifModel

    Scaler { id: scaler; currentWidth: Screen.width }
    function s(val) { return scaler.s(val); }

    MatugenColors { id: _theme }
    readonly property color base:     _theme.base
    readonly property color mantle:   _theme.mantle
    readonly property color crust:    _theme.crust
    readonly property color text:     _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color blue:     _theme.blue
    readonly property color green:    _theme.green
    readonly property color yellow:   _theme.yellow
    readonly property color red:      _theme.red
    readonly property color peach:    _theme.peach
    readonly property color teal:     _theme.teal
    readonly property color mauve:    _theme.mauve

    // ── State ─────────────────────────────────────────────────────────────────
    property int    cpuPct:    0
    property int    ramPct:    0
    property int    ramUsed:   0
    property int    ramTotal:  0
    property int    cpuTemp:   0
    property string netRx:     "0 KB/s"
    property string netTx:     "0 KB/s"
    property string netIface:  "—"

    // ── Polling ───────────────────────────────────────────────────────────────
    Process {
        id: fetcher
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/sidepanel/sysinfo_fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text.trim());
                    window.cpuPct   = d.cpu       || 0;
                    window.ramPct   = d.ram_pct   || 0;
                    window.ramUsed  = d.ram_used  || 0;
                    window.ramTotal = d.ram_total || 0;
                    window.cpuTemp  = d.temp      || 0;
                    window.netRx    = d.rx        || "0 KB/s";
                    window.netTx    = d.tx        || "0 KB/s";
                    window.netIface = d.iface     || "—";
                } catch(e) {}
                reloadTimer.restart();
            }
        }
    }

    // Re-poll 2 s after script finishes (~2 s script + 2 s pause ≈ 4 s cycle)
    Timer {
        id: reloadTimer
        interval: 2000
        repeat: false
        onTriggered: fetcher.running = true
    }

    Component.onCompleted: fetcher.running = true

    // ── Colour helpers ────────────────────────────────────────────────────────
    function barColor(pct) {
        if (pct >= 85) return red;
        if (pct >= 60) return yellow;
        return blue;
    }
    function tempColor(t) {
        if (t >= 85) return red;
        if (t >= 70) return yellow;
        return teal;
    }

    // ── Root card ─────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: base
        radius: s(18)

        // subtle border
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: s(18)
            border.color: surface1
            border.width: 1
        }

        ColumnLayout {
            anchors { fill: parent; margins: s(24) }
            spacing: s(20)

            // ── Header ──────────────────────────────────────────────────────
            Text {
                text: "System"
                color: text
                font.pixelSize: s(20)
                font.family: "Iosevka Nerd Font"
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            // ── CPU ─────────────────────────────────────────────────────────
            StatRow {
                label: "  CPU"
                value: cpuPct + "%"
                pct:   cpuPct
                accent: barColor(cpuPct)
                s_fn:  window.s
                textClr: text; subClr: subtext0; surfClr: surface0; crustClr: crust
            }

            // ── RAM ─────────────────────────────────────────────────────────
            StatRow {
                label: "  RAM"
                value: (ramUsed / 1024).toFixed(1) + " / " + (ramTotal / 1024).toFixed(1) + " GB"
                pct:   ramPct
                accent: barColor(ramPct)
                s_fn:  window.s
                textClr: text; subClr: subtext0; surfClr: surface0; crustClr: crust
            }

            // ── Temperature ─────────────────────────────────────────────────
            StatRow {
                label: "  Temp"
                value: cpuTemp + "°C"
                pct:   Math.min(100, Math.max(0, (cpuTemp - 30) * 100 / 70))
                accent: tempColor(cpuTemp)
                s_fn:  window.s
                textClr: text; subClr: subtext0; surfClr: surface0; crustClr: crust
            }

            // ── Divider ─────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: surface1
            }

            // ── Network ─────────────────────────────────────────────────────
            Text {
                text: "  " + netIface
                color: subtext0
                font.pixelSize: s(13)
                font.family: "Iosevka Nerd Font"
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: s(12)

                NetBadge {
                    Layout.fillWidth: true
                    icon: "󰁅"
                    label: "Download"
                    speed: netRx
                    accent: teal
                    s_fn: window.s
                    baseClr: surface0; textClr: text; subClr: subtext0
                }
                NetBadge {
                    Layout.fillWidth: true
                    icon: "󰁝"
                    label: "Upload"
                    speed: netTx
                    accent: mauve
                    s_fn: window.s
                    baseClr: surface0; textClr: text; subClr: subtext0
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // ── Reusable: stat row with label, value, and progress bar ────────────────
    component StatRow: ColumnLayout {
        property string label
        property string value
        property real   pct
        property color  accent
        property var    s_fn
        property color  textClr
        property color  subClr
        property color  surfClr
        property color  crustClr

        Layout.fillWidth: true
        spacing: s_fn(6)

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: label
                color: textClr
                font.pixelSize: s_fn(14)
                font.family: "Iosevka Nerd Font"
            }
            Item { Layout.fillWidth: true }
            Text {
                text: value
                color: accent
                font.pixelSize: s_fn(13)
                font.family: "Iosevka Nerd Font"
                font.bold: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: s_fn(6)
            radius: s_fn(3)
            color: surfClr

            Rectangle {
                width: parent.width * (pct / 100)
                height: parent.height
                radius: parent.radius
                color: accent
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
    }

    // ── Reusable: network speed badge ─────────────────────────────────────────
    component NetBadge: Rectangle {
        property string icon
        property string label
        property string speed
        property color  accent
        property var    s_fn
        property color  baseClr
        property color  textClr
        property color  subClr

        height: s_fn(72)
        radius: s_fn(12)
        color: baseClr

        ColumnLayout {
            anchors.centerIn: parent
            spacing: s_fn(2)

            Text {
                text: icon
                color: accent
                font.pixelSize: s_fn(22)
                font.family: "Iosevka Nerd Font"
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: speed
                color: textClr
                font.pixelSize: s_fn(13)
                font.family: "Iosevka Nerd Font"
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: label
                color: subClr
                font.pixelSize: s_fn(11)
                font.family: "Iosevka Nerd Font"
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
