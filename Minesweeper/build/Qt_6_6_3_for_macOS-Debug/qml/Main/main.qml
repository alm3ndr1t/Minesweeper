import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    visible: true
    width: 600
    height: 800
    title: "Minesweeper"

    property int gridSize: 10
    property int bombCount: 10
    property var bombPositions: []
    property bool gameEnded: false

    function initializeBombs() {
        bombPositions = [];
        var bombCount = 0;
        var maxBombIndex = gridSize * gridSize;

        while (bombCount < this.bombCount) {
            var randomIndex = Math.floor(Math.random() * maxBombIndex);
            var x = randomIndex % gridSize;
            var y = Math.floor(randomIndex / gridSize);

            var isDuplicate = bombPositions.some(function(position) {
                return position.x === x && position.y === y;
            });

            if (!isDuplicate) {
                bombPositions.push({x: x, y: y});
                bombCount++;
            }
        }

        console.log("Bombs initialized:", bombPositions);
    }

    function countNearbyBombs(cellX, cellY) {
        var count = 0;
        for (var i = Math.max(0, cellX - 1); i <= Math.min(gridSize - 1, cellX + 1); i++) {
            for (var j = Math.max(0, cellY - 1); j <= Math.min(gridSize - 1, cellY + 1); j++) {
                if (i !== cellX || j !== cellY) {
                    if (bombPositions.some(pos => pos.x === i && pos.y === j)) {
                        count++;
                    }
                }
            }
        }
        return count;
    }

    function revealEmptyCells(cellX, cellY) {
        var cellsToCheck = [{ x: cellX, y: cellY }];
        var revealedCells = [];

        while (cellsToCheck.length > 0) {
            var cellToCheck = cellsToCheck.pop();
            var x = cellToCheck.x;
            var y = cellToCheck.y;

            for (var dx = -1; dx <= 1; dx++) {
                for (var dy = -1; dy <= 1; dy++) {
                    var newX = x + dx;
                    var newY = y + dy;
                    // Check if the new coordinates are within the grid bounds
                    if (newX >= 0 && newX < gridSize && newY >= 0 && newY < gridSize) {
                        var cellIndex = newX + newY * gridSize;
                        var cell = cellRepeater.itemAt(cellIndex);
                        if (cell && !cell.hasBomb && !cell.revealed && !revealedCells.some(function(revealedCell) {
                            return revealedCell.x === newX && revealedCell.y === newY;
                        })) {
                            cell.revealed = true;
                            revealedCells.push({ x: newX, y: newY });
                            var nearbyBombCount = countNearbyBombs(newX, newY);
                            if (nearbyBombCount === 0) {
                                cellsToCheck.push({ x: newX, y: newY }); // Add adjacent empty cell for further check
                            }
                        }
                    }
                }
            }
        }
    }

    function restartGame() {
        initializeBombs();
        cellRepeater.model = 0;
        cellRepeater.model = gridSize * gridSize;
        gameOverText.visible = false;
        gameEnded = false;
        console.log("Game restarted");
    }

    function gameOver() {
        gameEnded = true;
        gameOverText.visible = true;
        console.log("Game over");

        for (var i = 0; i < cellRepeater.count; i++) {
            var cell = cellRepeater.itemAt(i);
            cell.revealed = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Row {
            spacing: 10
            Layout.alignment: Qt.AlignHCenter

            Text {
                text: "Grid Size: " + gridSize + "x" + gridSize
                anchors.verticalCenter: parent.verticalCenter
            }

            Slider {
                id: gridSizeSlider
                property var validSizes: [10, 12, 14, 16]
                from: 0
                to: 3
                stepSize: 1
                value: validSizes.indexOf(gridSize)
                anchors.verticalCenter: parent.verticalCenter

                onValueChanged: {
                    gridSize = validSizes[value];
                    initializeBombs();
                    restartGame();
                }
            }
        }

        Row {
            spacing: 10
            Layout.alignment: Qt.AlignHCenter

            Text {
                text: "Bombs: " + bombCount
                anchors.verticalCenter: parent.verticalCenter
            }

            Slider {
                id: bombCountSlider
                from: 15
                to: Math.floor(gridSize * gridSize * 0.5)
                stepSize: 5
                value: bombCount
                anchors.verticalCenter: parent.verticalCenter

                onValueChanged: {
                    bombCount = value;
                    initializeBombs();
                    restartGame();
                }
            }
        }

        Button {
            id: restartButton
            text: "Restart"
            onClicked: {
                console.log("Restart button clicked");
                restartGame();
            }
            Layout.alignment: Qt.AlignHCenter
            width: 200
            height: 50
            font.pixelSize: 16
            background: Rectangle {
                color: restartButton.pressed ? "white" : "yellow"
                radius: 10
            }

            Behavior on background {
                ColorAnimation {
                    duration: 100
                }
            }
        }

        Rectangle {
            implicitWidth: gridSize * 32 + 35
            implicitHeight: gridSize * 32 + 35
            color: "#ADD8E6"
            Layout.alignment: Qt.AlignHCenter
            border.color: "#4682B4"
            border.width: 2
            radius: 5

            GridLayout {
                id: gameGrid
                columns: gridSize
                rows: gridSize
                anchors.fill: parent
                columnSpacing: 0
                rowSpacing: 0
                anchors.margins: 5

                Repeater {
                    id: cellRepeater
                    model: gridSize * gridSize
                    delegate: Rectangle {
                        implicitWidth: tileImage.implicitWidth
                        implicitHeight: tileImage.implicitHeight
                        border.color: "black"
                        radius: 5

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

                        Image {
                            id: tileImage
                            anchors.fill: parent
                            source: "qrc:/images/tiles.jpg"
                            sourceClipRect: {
                                var tileSize = 32;
                                if (parent.revealed) {
                                    if (parent.hasBomb) {
                                        return Qt.rect(tileSize * 9, 0, tileSize, tileSize); // Bomb tile
                                    } else {
                                        var nearbyBombCount = countNearbyBombs(index % gridSize, Math.floor(index / gridSize));
                                        return Qt.rect(tileSize * nearbyBombCount, 0, tileSize, tileSize); // Number tile
                                    }
                                } else if (parent.flagged) {
                                    return Qt.rect(tileSize * 11, 0, tileSize, tileSize); // Flagged tile
                                } else {
                                    return Qt.rect(tileSize * 10, 0, tileSize, tileSize); // Unrevealed tile
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.AllButtons

                            onClicked: function(event) {
                                if (gameEnded) return;
                                if (event.button === Qt.RightButton) {
                                    return; // Right-click handled by onPressAndHold
                                }
                                if (!parent.revealed) {
                                    parent.revealed = true;
                                    console.log("Cell clicked:", index, "Has bomb:", parent.hasBomb);

                                    if (!parent.hasBomb) {
                                        var nearbyBombCount = countNearbyBombs(index % gridSize, Math.floor(index / gridSize));
                                        if (nearbyBombCount === 0) {
                                            revealEmptyCells(index % gridSize, Math.floor(index / gridSize));
                                        } else {
                                            tileImage.sourceClipRect = Qt.rect(nearbyBombCount * 32, 0, 32, 32);
                                        }
                                    } else {
                                        gameOver();
                                    }
                                }
                            }

                            onPressAndHold: {
                                if (gameEnded) return;
                                if (!parent.revealed) {
                                    parent.flagged = !parent.flagged;
                                    console.log("Cell flagged:", index, "Flagged:", parent.flagged);
                                    // Force a visual update
                                    tileImage.sourceClipRect = tileImage.sourceClipRect;
                                }
                            }
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

    Component.onCompleted: {
        initializeBombs();
        restartGame();
    }
}
