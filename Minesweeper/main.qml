import QtQuick
import QtQuick.Controls

ApplicationWindow {
    visible: true
    width: 600
    height: 700
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

    onGridSizeChanged: {
        initializeBombs();
        restartGame();
    }

    onBombCountChanged: {
        initializeBombs();
        restartGame();
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

        Row {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter

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
            anchors.horizontalCenter: parent.horizontalCenter
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
            width: 400
            height: 400
            color: "#ADD8E6"
            anchors.horizontalCenter: parent.horizontalCenter
            border.color: "#4682B4"
            border.width: 2
            radius: 10

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
                                var tileSize = 32; // Assuming each tile in tiles.png is 32x32
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
                            onClicked: function(event) {
                                if (gameEnded) return;
                                if (!parent.revealed) {
                                    if (event.button === Qt.RightButton) {
                                        parent.flagged = !parent.flagged;
                                        console.log("Cell flagged:", index, "Flagged:", parent.flagged);
                                    } else {
                                        parent.revealed = true;
                                        console.log("Cell clicked:", index, "Has bomb:", parent.hasBomb);

                                        if (!parent.hasBomb) {
                                            var nearbyBombCount = countNearbyBombs(index % gridSize, Math.floor(index / gridSize));
                                            if (nearbyBombCount > 0) {
                                                tileImage.sourceRect = Qt.rect(nearbyBombCount * 32, 0, 32, 32);
                                            } else {
                                                revealEmptyCells(index % gridSize, Math.floor(index / gridSize));
                                            }
                                        } else {
                                            gameOver();
                                        }
                                    }
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
                        var nearbyBombCount = countNearbyBombs(i, j);
                        if (nearbyBombCount > 0) {
                            cell.getChildAt(0).sourceRect = Qt.rect(nearbyBombCount * 32, 0, 32, 32);
                        } else {
                            revealEmptyCells(i, j);
                        }
                    }
                }
            }
        }
    }

    function restartGame() {
        initializeBombs(); // Regenerate bomb positions
        cellRepeater.model = 0;
        cellRepeater.model = gridSize * gridSize;
        bombCountSlider.value = bombCount; // Reset the bombCountSlider
        gameOverText.visible = false;
        gameEnded = false;
        console.log("Game restarted");
    }

    function gameOver() {
        gameEnded = true;
        gameOverText.visible = true;
        console.log("Game over");

        var rows = Math.floor(cellRepeater.count / gridSize);

        for (var i = 0; i < cellRepeater.count; i++) {
            var cell = cellRepeater.itemAt(i);
            cell.revealed = true;

            if (cell.hasBomb) {
                cell.getChildAt(0).sourceClipRect = Qt.rect(9 * 32, 0, 32, 32); // Bomb tile
            } else {
                var x = i % gridSize;
                var y = Math.floor(i / gridSize);
                var nearbyBombCount = countNearbyBombs(x, y);
                cell.getChildAt(0).sourceClipRect = Qt.rect(nearbyBombCount * 32, 0, 32, 32); // Number tile
            }
        }
    }

    Component.onCompleted: {
        initializeBombs();
        restartGame();
    }
}
