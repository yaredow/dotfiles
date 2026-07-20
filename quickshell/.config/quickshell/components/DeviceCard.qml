pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property string statusText: ""
    property bool active: false
    property bool connecting: false
    property bool secured: false
    property bool showMenu: false
    property var menuModel: []

    signal clicked
    signal menuAction(string actionId)

    width: ListView.view ? ListView.view.width : 300
    height: 60
    radius: Config.radiusLarge

    border.width: 1
    border.color: root.active ? Config.accentColor : (root.connecting ? Config.warningColor : "transparent")

    color: mouseArea.containsMouse ? Config.surface1Color : Qt.alpha(Config.surface1Color, 0.4)
    Behavior on color { ColorAnimation { duration: Config.animDurationShort } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 15

        Rectangle {
            implicitWidth: 36
            implicitHeight: 36
            radius: Config.radiusLarge
            color: root.active ? Config.accentColor : (root.connecting ? Config.warningColor : Config.surface2Color)

            Text {
                anchors.centerIn: parent
                visible: !root.connecting
                text: root.icon
                font.family: Config.font
                font.pixelSize: Config.fontSizeIcon
                color: root.active ? Config.textReverseColor : Config.textColor
            }

            Text {
                anchors.centerIn: parent
                visible: root.connecting
                text: String.fromCodePoint(0xF0451)
                font.family: Config.font
                font.pixelSize: Config.fontSizeIcon
                color: Config.textReverseColor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.title
                color: Config.textColor
                font.bold: true
                font.pixelSize: Config.fontSizeNormal
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 5

                Text {
                    visible: root.subtitle !== ""
                    text: root.subtitle
                    color: Config.textColor
                    font.pixelSize: Config.fontSizeSmall
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.subtitle !== "" && root.statusText !== ""
                    text: "\u2022"
                    color: Config.textColor
                    font.pixelSize: Config.fontSizeSmall
                }

                Text {
                    text: root.statusText
                    font.pixelSize: Config.fontSizeSmall
                    font.bold: root.active
                    color: root.active ? Config.accentColor : (root.connecting ? Config.warningColor : Config.subtextColor)
                }
            }
        }

        Text {
            visible: root.secured && !root.active && !root.connecting
            text: String.fromCodePoint(0xF023B)
            font.family: Config.font
            color: Config.subtextColor
            font.pixelSize: Config.fontSizeSmall
        }

        Rectangle {
            visible: root.showMenu && !root.connecting
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            radius: 15
            color: menuMouse.containsMouse ? Config.surface2Color : "transparent"

            Text {
                anchors.centerIn: parent
                text: String.fromCodePoint(0xF0102)
                font.family: Config.font
                color: Config.textColor
                font.pixelSize: Config.fontSizeNormal
            }

            MouseArea {
                id: menuMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: menuPopup.open()
            }
        }
    }
}
