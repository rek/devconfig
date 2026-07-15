// A two-faced card that turns over in 3D to reveal its back. Put your main
// content (metrics, a list, whatever) as the default children — they become
// the FRONT — and hand the settings/extra content to `back`. FlipCard owns the
// Y-axis rotation, the shared card chrome, and the flip gestures.
//
//     FlipCard {
//         id: statsCard
//         cardWidth: 380; cardHeight: 246
//
//         front: [ Text { text: "front"; anchors.centerIn: parent } ]
//         back:  [ Text { text: "back";  anchors.centerIn: parent } ]
//         // a control in `back` can flip home with: statsCard.showFront()
//     }
//
// Gestures (each independently toggleable):
//   • clickFrontToFlip — click anywhere on the front turns to the back.
//   • clickBackToFlip  — click anywhere on the back turns home (off by default,
//                        so the back's own controls keep their clicks).
//   • dragToFlip       — a horizontal drag past dragThreshold on either face
//                        turns to the other side.
// A gesture always plays the whole animation; the card never rests mid-flip.
//
// Content slots are aliased to real child holders (not Loaders), so any `id:`
// you declare inside front/back content stays visible to the rest of your file
// — e.g. a PanelWindow can still bind to a ToggleButton declared in `back`.

import QtQuick

Item {
    id: root

    // === Geometry & chrome ===
    property real  cardWidth:   380
    property real  cardHeight:  246
    property real  cardRadius:  6
    property color background:  "#b8070b08"   // ~72% alpha near-black green tint
    property color borderColor: "#00ff88"
    property int   borderWidth: 2

    // === Behavior ===
    property int  duration:         450
    property bool clickFrontToFlip: true
    property bool clickBackToFlip:  false
    property bool dragToFlip:       true
    property real dragThreshold:    24

    // === Content slots ===
    // `front:`/`back:` take a list of items. They're aliased to real child
    // holders (not Loaders), so any `id:` declared inside keeps its declaring
    // file's scope and stays referenceable from outside (e.g. a PanelWindow
    // binding to a ToggleButton you put in `back`). Not the default property,
    // so the component's own face Rectangles below aren't swept into a slot.
    property alias front: frontHolder.data
    property alias back: backHolder.data

    // === State ===
    property real flipAngle: 0                       // 0 = front, 180 = back
    readonly property bool showingBack: flipAngle > 90

    function showFront() { flipAngle = 0; }
    function showBack()  { flipAngle = 180; }
    function flip()      { flipAngle = showingBack ? 0 : 180; }

    implicitWidth:  cardWidth
    implicitHeight: cardHeight
    width:  cardWidth
    height: cardHeight

    Behavior on flipAngle {
        NumberAnimation { duration: root.duration; easing.type: Easing.OutCubic }
    }

    // 3D turn around the vertical axis through the card's center.
    transform: Rotation {
        origin.x: root.width / 2
        origin.y: root.height / 2
        axis { x: 0; y: 1; z: 0 }
        angle: root.flipAngle
    }

    // ============================================================
    // FRONT
    // ============================================================
    Rectangle {
        anchors.fill: parent
        visible: !root.showingBack
        radius: root.cardRadius
        color: root.background
        border.color: root.borderColor
        border.width: root.borderWidth

        // Flip gesture, declared BEFORE the content holder so content stacks on
        // top and keeps its own clicks. Plain text passes events down to here,
        // so clicking the bare card still flips. A drag past the threshold fires
        // once and disarms, so the card always completes the turn.
        FlipGesture {
            anchors.fill: parent
            clickEnabled: root.clickFrontToFlip
            dragEnabled:  root.dragToFlip
            dragThreshold: root.dragThreshold
            onTriggered: root.showBack()
        }

        Item { id: frontHolder; anchors.fill: parent }
    }

    // ============================================================
    // BACK — pre-rotated 180° so its content reads correctly once the card has
    // turned to face away.
    // ============================================================
    Rectangle {
        id: backFace
        anchors.fill: parent
        visible: root.showingBack
        transform: Rotation {
            origin.x: backFace.width / 2
            origin.y: backFace.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: 180
        }
        radius: root.cardRadius
        color: root.background
        border.color: root.borderColor
        border.width: root.borderWidth

        FlipGesture {
            anchors.fill: parent
            clickEnabled: root.clickBackToFlip
            dragEnabled:  root.dragToFlip
            dragThreshold: root.dragThreshold
            onTriggered: root.showFront()
        }

        Item { id: backHolder; anchors.fill: parent }
    }
}
