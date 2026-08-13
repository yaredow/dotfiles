pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config

Singleton {
    id: root

    property bool dndEnabled: false

    function toggleDnd() {
        dndEnabled = !dndEnabled
        if (dndEnabled) {
            for (let i = 0; i < notifications.length; i++) {
                if (notifications[i] && notifications[i].popup) {
                    notifications[i].popup = false
                    notifications[i].tickTimer.stop()
                }
            }
        }
    }

    function setDnd(enabled) {
        if (dndEnabled !== enabled) {
            dndEnabled = enabled
            if (enabled) {
                for (let i = 0; i < notifications.length; i++) {
                    if (notifications[i] && notifications[i].popup) {
                        notifications[i].popup = false
                        notifications[i].tickTimer.stop()
                    }
                }
            }
        }
    }

    readonly property list<NotifWrapper> notifications: []
    readonly property list<NotifWrapper> popups: notifications.filter(n => n && n.popup)

    readonly property int count: notifications.length
    readonly property int activePopupCount: popups.length

    property int hoveredNotificationId: -1

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        actionIconsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            console.log("[Notif] Received:", notif.appName, "-", notif.summary)
            notif.tracked = true
            const showPopup = !root.dndEnabled
            const wrapper = notifComponent.createObject(root, {
                "popup": showPopup,
                "notification": notif
            })
            if (wrapper) {
                root.notifications.push(wrapper)
                if (showPopup) wrapper.startLifecycle()
            } else {
                console.log("[Notif] FAILED to create wrapper")
            }
        }
    }

    component NotifWrapper: QtObject {
        id: wrapper

        property bool popup: false

        property int totalTime: Config.notifTimeout
        property int remainingTime: Config.notifTimeout
        property real progress: 0.0

        readonly property Timer tickTimer: Timer {
            interval: 50
            repeat: true
            running: false
            onTriggered: {
                if (wrapper.remainingTime > 0) {
                    wrapper.remainingTime -= interval
                    wrapper.progress = 1.0 - (wrapper.remainingTime / wrapper.totalTime)
                    if (wrapper.remainingTime <= 0) {
                        wrapper.remainingTime = 0
                        wrapper.progress = 1.0
                        stop()
                        wrapper.popup = false
                    }
                }
            }
        }

        function startLifecycle() {
            remainingTime = totalTime
            progress = 0.0
            tickTimer.start()
        }

        property bool isPaused: root.hoveredNotificationId === (notification ? notification.id : -1)

        onIsPausedChanged: {
            if (isPaused) {
                if (tickTimer.running) tickTimer.stop()
            } else {
                if (popup && remainingTime > 0 && !tickTimer.running) tickTimer.start()
                else if (popup && remainingTime <= 0) popup = false
            }
        }

        readonly property date time: new Date()
        readonly property string timeStr: {
            const diff = new Date().getTime() - time.getTime()
            const minutes = Math.floor(diff / 60000)
            if (minutes < 1) return "now"
            if (minutes < 60) return minutes + "m ago"
            const hours = Math.floor(minutes / 60)
            if (hours < 24) return hours + "h ago"
            return Math.floor(hours / 24) + "d ago"
        }

        required property Notification notification

        readonly property int notifId: notification ? notification.id : -1
        readonly property string summary: notification ? (notification.summary || "") : ""
        readonly property string body: notification ? (notification.body || "") : ""
        readonly property string appIcon: notification ? (notification.appIcon || "") : ""
        readonly property string appName: notification ? (notification.appName || "System") : "System"
        readonly property string image: notification ? (notification.image || "") : ""
        readonly property int urgency: notification ? notification.urgency : 0
        readonly property bool isUrgent: urgency === 2
        readonly property var actions: notification ? (notification.actions || []) : []
        readonly property bool hasActions: actions && actions.length > 0

        readonly property Connections conn: Connections {
            target: wrapper.notification ? wrapper.notification.Retainable : null
            function onDropped() {
                wrapper.tickTimer.stop()
                root.notifications = root.notifications.filter(w => w !== wrapper)
            }
            function onAboutToDestroy() {
                wrapper.tickTimer.stop()
                wrapper.destroy()
            }
        }
    }

    Component {
        id: notifComponent
        NotifWrapper {}
    }

    function setHovered(notifId) { hoveredNotificationId = notifId }
    function clearHovered() { hoveredNotificationId = -1 }

    function expireNotification(notifId) {
        for (let i = 0; i < notifications.length; i++) {
            if (notifications[i].notifId === notifId) {
                notifications[i].popup = false
                notifications[i].tickTimer.stop()
                break
            }
        }
    }

    function removeNotification(notifId) {
        for (let i = 0; i < notifications.length; i++) {
            if (notifications[i].notifId === notifId) {
                const wrapper = notifications[i]
                wrapper.popup = false
                wrapper.tickTimer.stop()
                if (wrapper.notification) wrapper.notification.dismiss()
                break
            }
        }
    }

    function clearAll() {
        const toRemove = notifications.slice()
        for (const wrapper of toRemove) {
            if (wrapper) {
                wrapper.tickTimer.stop()
                if (wrapper.notification) wrapper.notification.dismiss()
            }
        }
    }

    function getIconSource(appIcon, image) {
        if (image && image !== "") {
            if (image.startsWith("/")) return "file://" + image
            if (image.startsWith("file://") || image.startsWith("image://")) return image
            return image
        }
        if (appIcon && appIcon !== "") {
            if (appIcon.startsWith("/")) return "file://" + appIcon
            if (appIcon.startsWith("file://") || appIcon.startsWith("image://")) return appIcon
            return "image://icon/" + appIcon
        }
        return ""
    }
}
