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
        const daysFull = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
        let result = formatStr;
        result = result.replace(/\bdddd\b/g, daysFull[d.getDay()]);
        result = result.replace(/\bddd\b/g, days[d.getDay()]);
        result = result.replace(/\bdd\b/g, String(d.getDate()).padStart(2,'0'));
        result = result.replace(/\bd\b/g, String(d.getDate()));
        result = result.replace(/\bMMM\b/g, months[d.getMonth()]);
        result = result.replace(/\bHH\b/g, String(d.getHours()).padStart(2,'0'));
        result = result.replace(/\bhh\b/g, String(d.getHours()).padStart(2,'0'));
        result = result.replace(/\bmm\b/g, String(d.getMinutes()).padStart(2,'0'));
        return result;
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.date = new Date()
    }
}
