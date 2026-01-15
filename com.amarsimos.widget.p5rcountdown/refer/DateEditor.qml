import QtQuick 2.12
import QtQuick.Controls 2.12

import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P

NVG.Window {
    id: dialog

    title: widget.title
    visible: true
    minimumWidth: 500
    minimumHeight: 400
    transientParent: widget.NVG.View.window

    Page {
        anchors.fill: parent

        header: TitleBar { text: dialog.title }

        P.ObjectPreferenceGroup {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16

            label: qsTr("Widget Settings")
            defaultValue: widget.settings
            syncProperties: true

            P.PreferenceLoader {
                name: "weather"
                sourceComponent: widget.weatherValue?.update.preference ?? null
            }

            P.SwitchPreference {
                name: "animation"
                label: qsTr("Enable Animation")
                defaultValue: true
            }

            P.SwitchPreference {
                name: "inverse"
                label: qsTr("Invert Color")
                defaultValue: false
            }
        }
    }
}
