pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property date date: new Date()

    function format(formatStr) {
        const d = new Date();
        const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
        const days = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
        let result = formatStr;
        result = result.replace("hh", String(d.getHours()).padStart(2,'0'));
        result = result.replace("mm", String(d.getMinutes()).padStart(2,'0'));
        result = result.replace("dd", String(d.getDate()).padStart(2,'0'));
        result = result.replace("MMM", months[d.getMonth()]);
        result = result.replace("ddd", days[d.getDay()]);
        return result;
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.date = new Date()
    }
}
