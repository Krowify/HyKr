// Native Quickshell notification daemon: Quickshell.Services.Notifications
// implements the D-Bus notification spec directly, so nothing external
// (swaync, dunst, mako) needs to run alongside this theme's dock.
// Structure follows mystiafin/shell's services/NotificationService.qml --
// two models (history + transient popups) fed by one NotificationServer --
// with urgency exposed for the popup/history border color.
pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    property alias historyModel: historyListModel
    property alias popupModel: popupListModel
    readonly property int historyCount: historyListModel.count
    readonly property int unreadCount: popupListModel.count
    property bool doNotDisturb: false

    function iconSource(notification) {
        const source = notification.image || notification.appIcon
        if (!source)
            return ""
        if (source.startsWith("/"))
            return "file://" + source
        if (source.includes(":"))
            return source
        return Quickshell.iconPath(source)
    }

    function urgencyName(notification) {
        switch (notification.urgency) {
        case NotificationUrgency.Critical: return "critical"
        case NotificationUrgency.Low: return "low"
        default: return "normal"
        }
    }

    function record(notification) {
        return {
            notification: notification,
            notificationId: notification.id,
            appName: notification.appName || "Notification",
            summary: notification.summary || "",
            body: notification.body || "",
            icon: iconSource(notification),
            urgency: urgencyName(notification),
            receivedAt: new Date()
        };
    }

    function removeById(notificationId) {
        for (let i = 0; i < historyListModel.count; i++) {
            if (historyListModel.get(i).notificationId === notificationId) {
                historyListModel.remove(i);
                break;
            }
        }
        removePopupById(notificationId);
    }

    function removePopupById(notificationId) {
        for (let i = 0; i < popupListModel.count; i++) {
            if (popupListModel.get(i).notificationId === notificationId) {
                popupListModel.remove(i);
                return;
            }
        }
    }

    function dismiss(notificationId) {
        for (let i = 0; i < historyListModel.count; i++) {
            const rec = historyListModel.get(i);
            if (rec.notificationId === notificationId) {
                removeById(notificationId);
                if (rec.notification)
                    rec.notification.dismiss();
                return;
            }
        }
    }

    function clear() {
        const tracked = [];
        for (let i = 0; i < historyListModel.count; i++)
            tracked.push(historyListModel.get(i).notification);
        historyListModel.clear();
        popupListModel.clear();
        for (const notification of tracked) {
            if (notification)
                notification.dismiss();
        }
    }

    ListModel { id: historyListModel }
    ListModel { id: popupListModel }

    NotificationServer {
        id: server

        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        actionsSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true;
            root.removeById(notification.id);
            const rec = root.record(notification);
            historyListModel.insert(0, rec);
            if (!root.doNotDisturb)
                popupListModel.append(rec);
        }
    }
}
