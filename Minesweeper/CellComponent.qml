import QtQuick 2.15

Rectangle {
    property int index
    property int gridSize
    property var bombPositions
    property bool gameEnded
    property bool hasBomb: false
    property bool revealed: false
    property bool flagged: false

    width: 400 / gridSize
    height: 400 / gridSize
    border.color: "black"
    color: "lightgray"

    Component.onCompleted: {
        for (var i = 0; i < bombPositions.length; i++) {
            if (bombPositions[i].x === index % gridSize && bombPositions[i].y === Math.floor(index / gridSize)) {
                hasBomb = true;
                break;
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: function(event) {
            if (gameEnded) return; // Prevent actions if game has ended
            if (!parent.revealed) {
                if (event.button === Qt.RightButton) {
                    parent.flagged = !parent.flagged;
                    parent.color = parent.flagged ? "yellow" : "lightgray";
                    textItem.text = parent.flagged ? "F" : "";
                    textItem.color = "green";
                    textItem.visible = parent.flagged;
                    console.log("Cell flagged:", index, "Flagged:", parent.flagged);
                } else {
                    if (!parent.flagged) {
                        parent.color = "white";
                        parent.revealed = true;
                        console.log("Cell clicked:", index, "Has bomb:", parent.hasBomb);

                        if (!parent.hasBomb) {
                            var nearbyBombCount = countNearbyBombs(index % gridSize, Math.floor(index / gridSize));
                            if (nearbyBombCount > 0) {
                                textItem.text = nearbyBombCount.toString();
                                textItem.color = "black";
                                textItem.visible = true;
                            } else {
                                revealEmptyCells(index % gridSize, Math.floor(index / gridSize));
                            }
                        } else {
                            textItem.text = "B";
                            textItem.color = "red";
                            textItem.visible = true;
                            gameOver();
                        }
                    }
                }
            }
        }
    }

    Text {
        id: textItem
        anchors.centerIn: parent
        text: ""
        color: "black"
        visible: false
    }
}
