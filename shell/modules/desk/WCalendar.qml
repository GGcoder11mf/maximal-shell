import QtQuick
import Quickshell
import qs.services
import "../dashboard"

// Month calendar (scroll to change month, click the title for today)
Item {
    property int uid: -1
    implicitWidth: 320
    implicitHeight: 318
    SystemClock { id: clock; precision: SystemClock.Hours }
    Calendar { anchors.fill: parent; anchors.margins: 14; today: clock.date }
}
