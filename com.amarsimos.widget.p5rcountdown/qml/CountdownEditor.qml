import NERvGear 1.0 as NVG
import NERvGear.Controls 1.0
import NERvGear.Preferences 1.0 as P
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

NVG.Window {
    id: dialog

    title: qsTr("Countdown Settings")
    visible: false
    minimumWidth: 500
    minimumHeight: 400
    transientParent: widget.NVG.View.window

    Page {
        anchors.fill: parent

        P.ObjectPreferenceGroup {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            label: qsTr("Widget Settings")
            defaultValue: widget.settings
            Component.onCompleted: {
                if (!widget.settings.eventText)
                    widget.settings.eventText = qsTr("GP更新");

                if (!widget.settings.bottomText)
                    widget.settings.bottomText = qsTr("盗取GP的心");

            }

            // Custom control for the event text
            Control {
                width: parent.width
                padding: 0

                contentItem: RowLayout {
                    Label {
                        text: qsTr("Event")
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    TextField {
                        text: widget.settings.eventText
                        placeholderText: qsTr("Enter your event here")
                        Layout.minimumWidth: 200
                        onTextChanged: {
                            if (widget.settings.eventText !== text)
                                widget.settings.eventText = text;

                        }
                    }

                }

            }

            // Custom control for the bottom text
            Control {
                width: parent.width
                padding: 0

                contentItem: RowLayout {
                    Label {
                        text: qsTr("Todo Message")
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    TextField {
                        text: widget.settings.bottomText || ""
                        placeholderText: qsTr("enter your todo message here")
                        Layout.minimumWidth: 200
                        onTextChanged: {
                            if (widget.settings.bottomText !== text)
                                widget.settings.bottomText = text;

                        }
                    }

                }

            }

            // Custom control for the target date
            Control {
                width: parent.width
                padding: 0

                contentItem: RowLayout {
                    Label {
                        text: qsTr("Target Date")
                        Layout.fillWidth: true
                    }

                    TextField {
                        Layout.minimumWidth: 150
                        placeholderText: "yyyy/mm/dd"
                        // Initialize and bind text
                        text: {
                            const date = widget.settings.targetDate ? new Date(widget.settings.targetDate) : new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
                            return Qt.formatDate(date, "yyyy/MM/dd");
                        }
                        onEditingFinished: {
                            // Regex match for yyyy/mm/dd (allowing - or . separators too)
                            var match = text.match(/^(\d{4})[\/.-](\d{1,2})[\/.-](\d{1,2})$/);
                            if (match) {
                                var y = parseInt(match[1]);
                                var m = parseInt(match[2]) - 1; // JS month is 0-indexed
                                var d = parseInt(match[3]);
                                var newDate = new Date(y, m, d);
                                // Validate date existence
                                if (newDate.getFullYear() === y && newDate.getMonth() === m && newDate.getDate() === d)
                                    widget.settings.targetDate = newDate.toISOString();

                            }
                            // Refresh display to match stored setting (autocorrect invalid input)
                            const current = widget.settings.targetDate ? new Date(widget.settings.targetDate) : new Date();
                            text = Qt.formatDate(current, "yyyy/MM/dd");
                        }
                    }

                }

            }

        }

        header: TitleBar {
            text: dialog.title
        }

    }

}
