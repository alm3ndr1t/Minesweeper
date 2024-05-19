import QtQuick 2.15
import QtQuick.Controls 2.15
import content

App {
    width: 600
    height: 700
    visible: true

    property int gridSize: 10
    property int bombCount: Math.min(gridSize * gridSize / 5, 20)
    property var bombPositions: []
    property bool gameEnded: false // Track whether the game has ended

    function initializeBombs() {
        bombPositions = [];
        var bombCount = 0;
        while (bombCount < this.bombCount) {
            var x = Math.floor(Math.random() * gridSize);
            var y = Math.floor(Math.random() * gridSize);
            var hasBomb = false;
            for (var i = 0; i < bombPositions.length; i++) {
                if (bombPositions[i].x === x && bombPositions[i].y === y) {
                    hasBomb = true;
                    break;
                }
            }
            if (!hasBomb) {
                bombPositions.push({x: x, y: y});
                bombCount++;
            }
        }
        console.log("Bombs initialized:", bombPositions);
    }

    onGridSizeChanged: {
        bombCount = Math.min(gridSize * gridSize / 5, 20);
        initializeBombs();
    }

    Column {
        anchors.fill: parent
        spacing: 10
        anchors.horizontalCenter: parent.horizontalCenter

        Row {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: "Grid Size: " + gridSize + "x" + gridSize
                anchors.verticalCenter: parent.verticalCenter
            }

            Slider {
                id: gridSizeSlider
                from: 0
                to: 3
                stepSize: 1
                value: (gridSize - 10) / 2
                anchors.verticalCenter: parent.verticalCenter

                onValueChanged: {
                    gridSize = [10, 12, 14, 16][value];
                    initializeBombs();
                    restartGame();
                }
            }
        }

        Text {
            id: bombCountText
            text: "Bombs: " + bombCount
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Button {
            text: "Restart"
            onClicked: {
                console.log("Restart button clicked");
                restartGame();
            }
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            width: 400
            height: 400
            color: "lightblue"
            anchors.horizontalCenter: parent.horizontalCenter

            Grid {
                id: gameGrid
                columns: gridSize
                rows: gridSize
                spacing: 2
                anchors.centerIn: parent

                Repeater {
                    id: cellRepeater
                    model: gridSize * gridSize
                    delegate: Rectangle {
                        width: 400 / gridSize
                        height: 400 / gridSize
                        border.color: "black"
                        color: "lightgray"

                        property bool hasBomb: false
                        property bool revealed: false
                        property bool flagged: false

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
                                        console.log("Cell flagged:", index, "Flagged:", parent.flagged);
                                    } else {
                                        parent.color = "white";
                                        parent.revealed = true;
                                        console.log("Cell clicked:", index, "Has bomb:", parent.hasBomb);

                                        if (!parent.hasBomb) {
                                            var nearbyBombCount = countNearbyBombs(index % gridSize, Math.floor(index / gridSize));
                                            if (nearbyBombCount > 0) {
                                                textItem.text = nearbyBombCount.toString();
                                                textItem.visible = true;
                                            } else {
                                                revealEmptyCells(index % gridSize, Math.floor(index / gridSize));
                                            }
                                        } else {
                                            textItem.visible = true;
                                            bombCount--;
                                            bombCountText.text = "Bombs: " + bombCount;
                                            gameOver();
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            id: textItem
                            anchors.centerIn: parent
                            text: parent.flagged ? "F" : (parent.hasBomb ? "B" : "")
                            color: parent.flagged ? "green" : (parent.hasBomb ? "red" : "black")
                            visible: false
                        }
                    }
                }
            }
        }

        Text {
            id: gameOverText
            text: "Game Over"
            color: "red"
            font.pixelSize: 30
            visible: false
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    function countNearbyBombs(cellX, cellY) {
        var count = 0;
        for (var i = Math.max(0, cellX - 1); i <= Math.min(gridSize - 1, cellX + 1); i++) {
            for (var j = Math.max(0, cellY - 1); j <= Math.min(gridSize - 1, cellY + 1); j++) {
                if (i !== cellX || j !== cellY) {
                    for (var k = 0; k < bombPositions.length; k++) {
                        if (bombPositions[k].x === i && bombPositions[k].y === j) {
                            count++;
                        }
                    }
                }
            }
        }
        return count;
    }

    function revealEmptyCells(cellX, cellY) {
        for (var i = Math.max(0, cellX - 1); i <= Math.min(gridSize - 1, cellX + 1); i++) {
            for (var j = Math.max(0, cellY - 1); j <= Math.min(gridSize - 1, cellY + 1); j++) {
                if (i !== cellX || j !== cellY) {
                    var cellIndex = i + j * gridSize;
                    var cell = cellRepeater.itemAt(cellIndex);
                    if (cell && !cell.revealed && !cell.hasBomb) {
                        cell.revealed = true;
                        cell.color = "white";
                        var nearbyBombCount = countNearbyBombs(i, j);
                        if (nearbyBombCount > 0) {
                            cell.getChildAt(0).text = nearbyBombCount.toString();
                            cell.getChildAt(0).visible = true;
                        } else {
                            revealEmptyCells(i, j);
                        }
                    }
                }
            }
        }
    }

    function restartGame() {
        initializeBombs();
        cellRepeater.model = 0; // Reset the model to clear the grid
        cellRepeater.model = gridSize * gridSize; // Reassign the model to recreate the grid
        bombCountText.text = "Bombs: " + bombCount;
        gameOverText.visible = false;
        gameEnded = false; // Reset the game status
        console.log("Game restarted");
    }

    function gameOver() {
        gameEnded = true; // Set the game status to ended
        gameOverText.visible = true;
        console.log("Game over");
        for (var i = 0; i < cellRepeater.count; i++) {
            var cell = cellRepeater.itemAt(i);
            if (cell.hasBomb) {
                cell.color = "red";
                cell.revealed = true;
            }
        }
    }

    Component.onCompleted: initializeBombs
}
