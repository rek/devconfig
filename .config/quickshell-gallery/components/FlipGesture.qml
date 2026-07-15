// A transparent input layer that emits a single `triggered()` when the user
// either clicks (clickEnabled) or drags horizontally past dragThreshold
// (dragEnabled). A drag fires once mid-gesture and disarms, so the consumer
// can run a full animation without the gesture re-firing on every pixel.
//
// Sits behind real content: plain (non-interactive) content lets events fall
// through to here; interactive children declared on top keep their own clicks.
//
//     FlipGesture { anchors.fill: parent; onTriggered: card.flip() }

import QtQuick

MouseArea {
    id: root

    property bool clickEnabled: true
    property bool dragEnabled:  true
    property real dragThreshold: 24

    signal triggered()

    enabled: clickEnabled || dragEnabled
    cursorShape: clickEnabled ? Qt.PointingHandCursor : Qt.OpenHandCursor

    property real _startX: 0
    property bool _armed: false

    onPressed: { _startX = mouseX; _armed = true; }
    onPositionChanged: {
        if (dragEnabled && _armed
                && Math.abs(mouseX - _startX) > dragThreshold) {
            _armed = false;          // fire once per drag
            root.triggered();
        }
    }
    // A plain click (no drag past threshold) still flips when clickEnabled.
    onClicked: if (clickEnabled && _armed) root.triggered();
    onReleased: _armed = false
}
