/*
 * Copyright (C) 2025  Dominic Bussemas
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * twitchviewer is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.15
import QtMultimedia 5.15
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import QtGraphicalEffects 1.15

Item {
    id: playerPage
    
    // Properties
    property string channelName: ""
    property string requestedQuality: "best"
    property string currentStreamUrl: ""
    property string currentQuality: "Best"
    
    // Control visibility
    property bool isActive: false  // Set to true when player should be shown
    
    // Mini player properties
    property bool isMiniMode: false
    property point miniPosition: Qt.point(root.width - miniWidth - units.gu(2), 
                                           root.height - miniHeight - units.gu(2))
    property real miniWidth: units.gu(40)
    property real miniHeight: units.gu(22.5) // 16:9 aspect ratio
    
    // Animation state
    property bool isTransitioning: false
    
    // Visibility control
    visible: isActive
    
    // Always on top
    z: 999
    
    // CRITICAL: No anchors! Use explicit dimensions that can be animated
    // Start in fullscreen size
    width: root.width
    height: root.height
    x: 0
    y: 0
    
    // Debug state changes
    onStateChanged: {
        console.log("=== Player State Changed ===")
        console.log("New state:", state)
        console.log("PlayerPage - w:", width, "h:", height, "x:", x, "y:", y)
        console.log("===========================")
    }
    
    // States
    state: "fullscreen"
    
    states: [
        State {
            name: "fullscreen"
            PropertyChanges {
                target: playerPage
                width: root.width
                height: root.height
                x: 0
                y: 0
                isMiniMode: false
            }
            PropertyChanges {
                target: controlsOverlay
                visible: true
            }
            PropertyChanges {
                target: miniControls
                visible: false
            }
            PropertyChanges {
                target: playerContainer
                width: playerPage.width
                height: playerPage.height
                x: 0
                y: 0
            }
        },
        State {
            name: "mini"
            PropertyChanges {
                target: playerPage
                width: miniWidth
                height: miniHeight
                x: miniPosition.x
                y: miniPosition.y
                isMiniMode: true
            }
            PropertyChanges {
                target: controlsOverlay
                visible: false
            }
            PropertyChanges {
                target: miniControls
                visible: true
            }
            PropertyChanges {
                target: playerContainer
                width: playerPage.width
                height: playerPage.height
                x: 0
                y: 0
            }
        }
    ]
    
    transitions: [
        Transition {
            from: "fullscreen"
            to: "mini"
            SequentialAnimation {
                PropertyAction { target: playerPage; property: "isTransitioning"; value: true }
                PropertyAction { target: playerContainer; property: "y"; value: 0 }
                ParallelAnimation {
                    NumberAnimation {
                        target: playerPage
                        properties: "x,y,width,height"
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: playerContainer
                        properties: "width,height"
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
                PropertyAction { target: playerPage; property: "isTransitioning"; value: false }
            }
        },
        Transition {
            from: "mini"
            to: "fullscreen"
            SequentialAnimation {
                PropertyAction { target: playerPage; property: "isTransitioning"; value: true }
                PropertyAction { target: playerContainer; property: "y"; value: 0 }
                ParallelAnimation {
                    NumberAnimation {
                        target: playerPage
                        properties: "x,y,width,height"
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: playerContainer
                        properties: "width,height"
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
                PropertyAction { target: playerPage; property: "isTransitioning"; value: false }
            }
        }
    ]
    
    // Available qualities model
    ListModel {
        id: availableQualities
    }
    
    // Video player container (fullscreen)
    Rectangle {
        id: playerContainer
        // CRITICAL: No anchors.fill! Use explicit dimensions
        width: playerPage.width
        height: playerPage.height
        x: 0
        y: 0
        color: "black"
        
        // Drop shadow for mini mode
        layer.enabled: isMiniMode
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 4
            radius: 8.0
            samples: 17
            color: "#80000000"
        }
        
        Video {
            id: videoPlayer
            anchors.fill: parent
            autoPlay: false
            
            Component.onDestruction: {
                if (playbackState === MediaPlayer.PlayingState) {
                    stop()
                }
            }
            
            onStatusChanged: {
                if (status === MediaPlayer.InvalidMedia) {
                    statusLabel.text = "Error: Invalid media"
                    statusOverlay.visible = true
                } else if (status === MediaPlayer.NoMedia) {
                    statusLabel.text = i18n.tr('Loading stream...')
                    statusOverlay.visible = true
                } else if (status === MediaPlayer.LoadedMedia) {
                    statusOverlay.visible = false
                } else if (status === MediaPlayer.Loading || status === MediaPlayer.Buffering) {
                    statusLabel.text = i18n.tr('Buffering...')
                    statusOverlay.visible = true
                }
            }
            
            onErrorChanged: {
                if (error !== MediaPlayer.NoError) {
                        statusLabel.text = "Video error: " + errorString
                    statusOverlay.visible = true
                }
            }
            
            onPlaybackStateChanged: {
                if (playbackState === MediaPlayer.PlayingState) {
                    statusOverlay.visible = false
                    if (!isMiniMode) {
                        showControlsTemporarily()
                    }
                }
            }
        }
        
        // Status overlay (loading, errors)
        Rectangle {
            id: statusOverlay
            anchors.fill: parent
            color: "black"
            opacity: 0.8
            visible: false
            z: 10
            
            Column {
                anchors.centerIn: parent
                spacing: units.gu(2)
                width: parent.width - units.gu(4)
                
                ActivityIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: videoPlayer.status === MediaPlayer.Loading || 
                            videoPlayer.status === MediaPlayer.Buffering ||
                            statusLabel.text.indexOf("Fetching") >= 0
                    visible: running
                }
                
                Label {
                    id: statusLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: i18n.tr('Loading stream...')
                    color: "white"
                    font.pixelSize: units.gu(2)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }
        }
        
        // ========================================
        // GESTURE LAYER (Pinch, Tap, Swipe)
        // ========================================
        
        Item {
            id: gestureLayer
            anchors.fill: parent
            visible: !isTransitioning
            z: 5

            // Track gesture state
            property bool isSwiping: false
            property bool isDragging: false
            property real swipeStartY: 0
            property point dragStartPos
            
            
            // Tap to toggle controls - FULLSCREEN ONLY
            TapHandler {
                id: tapHandler
                enabled: !isMiniMode && !gestureLayer.isSwiping
                
                onTapped: {
                        if (controlsOverlay.opacity > 0) {
                        hideControls()
                    } else {
                        showControlsTemporarily()
                    }
                }
            }
            
            // Swipe up to close, swipe down to minimize - FULLSCREEN
            DragHandler {
                id: swipeHandler
                enabled: !isMiniMode && !gestureLayer.isDragging
                target: null  // Don't use target, manage Y manually
                yAxis.enabled: true
                xAxis.enabled: false

                property real startY: 0

                onActiveChanged: {
                    if (active) {
                        gestureLayer.isSwiping = true
                        startY = playerContainer.y
                        hideControls()
                            } else {
                        gestureLayer.isSwiping = false

                        var deltaY = playerContainer.y - startY
        
                        // Swipe DOWN = positive deltaY
                        if (deltaY > units.gu(15)) {
                                    minimizeToCorner()
                        }
                        // Swipe UP = negative deltaY
                        else if (deltaY < -units.gu(15)) {
                                    swipeOutAnimation.start()
                        }
                        else {
                                    // Snap back
                            resetSwipeAnimation.start()
                        }
                    }
                }

                onTranslationChanged: {
                    if (active) {
                        // Apply Y translation manually
                        playerContainer.y = translation.y
                    }
                }
            }
            
            // NO TAP HANDLER for mini mode - only pinch and drag
            
            // Drag mini player to reposition OR dismiss - MINI MODE
            DragHandler {
                id: miniDragHandler
                enabled: isMiniMode
                target: playerPage
                
                property point startPos
                property bool isInLeftSide: false
                
                onActiveChanged: {
                    if (active) {
                        gestureLayer.isDragging = true
                        startPos = Qt.point(playerPage.x, playerPage.y)
                        
                        // Determine if starting in left or right side
                        var centerX = playerPage.x + playerPage.width / 2
                        isInLeftSide = centerX < root.width / 2
                        
                            } else {
                        gestureLayer.isDragging = false
                        
                        var deltaX = playerPage.x - startPos.x
                        var currentCenterX = playerPage.x + playerPage.width / 2
                        
                                
                        // Smart dismiss logic: only from outer edges
                        var shouldDismiss = false
                        
                        if (isInLeftSide) {
                            // Started from left side - dismiss only if dragged far left
                            shouldDismiss = deltaX < -units.gu(15) && currentCenterX < root.width / 3
                        } else {
                            // Started from right side - dismiss only if dragged far right
                            shouldDismiss = deltaX > units.gu(15) && currentCenterX > (root.width * 2 / 3)
                        }
                        
                        if (shouldDismiss) {
                                    dismissMiniPlayer()
                        } else {
                                    // Snap to nearest corner
                            snapToNearestCorner()
                        }
                    }
                }
            }
        }
        
        // ========================================
        // FULLSCREEN CONTROLS OVERLAY
        // ========================================
        
        Rectangle {
            id: controlsOverlay
            anchors.fill: parent
            color: "transparent"
            visible: opacity > 0 && !isMiniMode
            opacity: 0
            z: 100
            
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
            
            // Dark gradient background
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.6) }
                    GradientStop { position: 0.3; color: "transparent" }
                    GradientStop { position: 0.7; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
                }
            }
            
            // Top bar - Channel name (left)
            Label {
                anchors {
                    top: parent.top
                    left: parent.left
                    margins: units.gu(2)
                }
                text: channelName
                color: "white"
                font.pixelSize: units.gu(2.5)
                font.bold: true
            }
            
            // Top bar - Minimize button (middle) - FIXED ICON
            Rectangle {
                id: minimizeButton
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    margins: units.gu(2)
                }
                width: units.gu(5)
                height: units.gu(5)
                color: Qt.rgba(0, 0, 0, 0.7)
                radius: units.gu(0.5)
                border.color: "white"
                border.width: units.dp(1)
                
                // Custom minimize icon (horizontal line)
                Rectangle {
                    anchors.centerIn: parent
                    width: units.gu(2.5)
                    height: units.gu(0.5)
                    color: "white"
                    radius: units.gu(0.25)
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                                minimizePlayer()
                    }
                }
            }
            
            // Top bar - Exit button (right) - FIXED to actually close
            Rectangle {
                id: exitButton
                anchors {
                    top: parent.top
                    right: parent.right
                    margins: units.gu(2)
                }
                width: units.gu(5)
                height: units.gu(5)
                color: Qt.rgba(0, 0, 0, 0.7)
                radius: units.gu(0.5)
                border.color: "white"
                border.width: units.dp(1)
                
                Icon {
                    anchors.centerIn: parent
                    name: "close"
                    width: units.gu(3)
                    height: units.gu(3)
                    color: "white"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                                closePlayer()
                    }
                }
            }
            
            // Center play/pause button
            Rectangle {
                anchors.centerIn: parent
                width: units.gu(8)
                height: units.gu(8)
                color: Qt.rgba(0, 0, 0, 0.7)
                radius: width / 2
                visible: videoPlayer.playbackState !== MediaPlayer.PlayingState || controlsOverlay.opacity > 0.5
                
                Icon {
                    anchors.centerIn: parent
                    name: videoPlayer.playbackState === MediaPlayer.PlayingState ? 
                          "media-playback-pause" : "media-playback-start"
                    width: units.gu(4)
                    height: units.gu(4)
                    color: "white"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                                if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
                            videoPlayer.pause()
                        } else {
                            videoPlayer.play()
                        }
                        showControlsTemporarily()
                    }
                }
            }
            
            // Bottom bar - Quality selector (right)
            Rectangle {
                id: qualityButton
                anchors {
                    bottom: parent.bottom
                    right: parent.right
                    margins: units.gu(2)
                }
                width: qualityLabel.width + units.gu(2)
                height: units.gu(5)
                color: Qt.rgba(0, 0, 0, 0.7)
                radius: units.gu(0.5)
                visible: availableQualities.count > 0
                
                Label {
                    id: qualityLabel
                    anchors.centerIn: parent
                    text: currentQuality
                    color: "white"
                    font.bold: true
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        qualityPopup.visible = !qualityPopup.visible
                        showControlsTemporarily()
                    }
                }
            }
            
            // Quality popup
            Rectangle {
                id: qualityPopup
                anchors {
                    right: parent.right
                    bottom: qualityButton.top
                    margins: units.gu(2)
                }
                width: units.gu(25)
                height: Math.min(qualityList.contentHeight + units.gu(4), parent.height * 0.6)
                color: ThemeManager.surfaceColor
                radius: units.gu(1)
                border.color: ThemeManager.borderColor
                border.width: units.dp(1)
                visible: false
                
                Column {
                    anchors {
                        fill: parent
                        margins: units.gu(1)
                    }
                    spacing: units.gu(1)
                    
                    Label {
                        text: i18n.tr("Quality")
                        font.bold: true
                        width: parent.width
                        color: ThemeManager.textPrimary
                    }
                    
                    ListView {
                        id: qualityList
                        width: parent.width
                        height: parent.height - units.gu(5)
                        clip: true
                        model: availableQualities
                        
                        delegate: Rectangle {
                            width: qualityList.width
                            height: units.gu(5)
                            color: currentQuality === model.name ? ThemeManager.accentColor : "transparent"
                            
                            Label {
                                anchors {
                                    left: parent.left
                                    leftMargin: units.gu(1)
                                    verticalCenter: parent.verticalCenter
                                }
                                text: model.name
                                color: currentQuality === model.name ? "white" : ThemeManager.textPrimary
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                                    switchQuality(model.name)
                                    qualityPopup.visible = false
                                    showControlsTemporarily()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // ========================================
        // MINI PLAYER CONTROLS
        // ========================================
        
        Rectangle {
            id: miniControls
            anchors.fill: parent
            color: "transparent"
            visible: false
            z: 100

            // Maximize button (top left)
            Rectangle {
                id: maximizeButton
                anchors {
                    top: parent.top
                    left: parent.left
                    margins: units.gu(0.5)
                }
                width: units.gu(3)
                height: units.gu(3)
                color: Qt.rgba(0, 0, 0, 0.8)
                radius: units.gu(0.5)
                border.color: "white"
                border.width: units.dp(1)

                // Icon: Maximize symbol (4 corners expanding outward)
                Icon {
                    anchors.centerIn: parent
                    name: "view-fullscreen"
                    width: units.gu(2)
                    height: units.gu(2)
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                                maximizePlayer()
                    }
                }
            }

            // Close button (top right)
            Rectangle {
                anchors {
                    top: parent.top
                    right: parent.right
                    margins: units.gu(0.5)
                }
                width: units.gu(3)
                height: units.gu(3)
                color: Qt.rgba(0, 0, 0, 0.8)
                radius: units.gu(0.5)
                border.color: "white"
                border.width: units.dp(1)

                Icon {
                    anchors.centerIn: parent
                    name: "close"
                    width: units.gu(2)
                    height: units.gu(2)
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                                dismissMiniPlayer()
                    }
                }
            }
            
            // Play/pause indicator (bottom left)
            Rectangle {
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    margins: units.gu(0.5)
                }
                width: units.gu(3)
                height: units.gu(3)
                color: Qt.rgba(0, 0, 0, 0.8)
                radius: units.gu(0.5)
                visible: videoPlayer.playbackState === MediaPlayer.PausedState
                
                Icon {
                    anchors.centerIn: parent
                    name: "media-playback-pause"
                    width: units.gu(2)
                    height: units.gu(2)
                    color: "white"
                }
            }
        }
    }
    
    // Auto-hide timer
    Timer {
        id: hideControlsTimer
        interval: 3000
        repeat: false
        onTriggered: hideControls()
    }
    
    // Reset swipe animation
    NumberAnimation {
        id: resetSwipeAnimation
        target: playerContainer
        property: "y"
        to: 0
        duration: 200
        easing.type: Easing.OutCubic
    }

    // Swipe out completely animation
    SequentialAnimation {
        id: swipeOutAnimation

        NumberAnimation {
            target: playerContainer
            property: "y"
            to: -playerPage.height
            duration: 200
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: {
                    closePlayer()
            }
        }
    }
    
    // ========================================
    // FUNCTIONS
    // ========================================
    
    function showControls() {
        controlsOverlay.opacity = 1
    }
    
    function hideControls() {
        controlsOverlay.opacity = 0
        qualityPopup.visible = false
    }
    
    function showControlsTemporarily() {
        showControls()
        hideControlsTimer.restart()
    }
    
    function minimizePlayer() {
        hideControls()

        // Reset any swipe offset
        playerContainer.y = 0

        // State transition will animate to mini position
        playerPage.state = "mini"

        // Notify Main.qml that we minimized (no reload!)
        playerMinimized()
    }

    function minimizeToCorner() {
        hideControls()

        // Set mini position to bottom-right corner
        miniPosition = Qt.point(
            root.width - miniWidth - units.gu(2),
            root.height - miniHeight - units.gu(2)
        )

        // Transition to mini state
        playerPage.state = "mini"

        // Notify Main.qml that we minimized
        playerMinimized()
    }
    
    function maximizePlayer() {
        
        // Reset any swipe offset
        playerContainer.y = 0
        
        // State transition will animate to fullscreen
        playerPage.state = "fullscreen"
        showControlsTemporarily()
        
        // Notify Main.qml that we maximized
        playerMaximized()
    }
    
    function closePlayer() {
        
        // Stop video
        if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
            videoPlayer.stop()
        }
        
        // Reset positions
        playerContainer.y = 0
        
        // Reset state
        isActive = false
        channelName = ""
        currentStreamUrl = ""
        currentQuality = "Best"
        availableQualities.clear()
        
        // Notify Main.qml
        playerClosed()
    }
    
    function dismissMiniPlayer() {
        
        // Animate out based on side
        var centerX = playerPage.x + playerPage.width / 2
        var targetX = (centerX < root.width / 2) ? 
                      -playerPage.width - units.gu(10) : 
                      root.width + units.gu(10)
        
        dismissAnimation.to = targetX
        dismissAnimation.start()
    }
    
    NumberAnimation {
        id: dismissAnimation
        target: playerPage
        property: "x"
        duration: 300
        easing.type: Easing.InCubic
        
        onStopped: {
            closePlayer()
        }
    }
    
    function snapToNearestCorner() {
        var centerX = playerPage.x + playerPage.width / 2
        var centerY = playerPage.y + playerPage.height / 2
        
        var margin = units.gu(2)
        
        // Determine which corner is closest
        var targetX = (centerX < root.width / 2) ? 
                      margin : 
                      root.width - playerPage.width - margin
        
        var targetY = (centerY < root.height / 2) ? 
                      margin : 
                      root.height - playerPage.height - margin
        
        // Update stored position
        miniPosition = Qt.point(targetX, targetY)
        
        // Animate to corner
        snapXAnimation.to = targetX
        snapYAnimation.to = targetY
        snapAnimation.start()
    }
    
    ParallelAnimation {
        id: snapAnimation
        
        NumberAnimation {
            id: snapXAnimation
            target: playerPage
            property: "x"
            duration: 200
            easing.type: Easing.OutCubic
        }
        
        NumberAnimation {
            id: snapYAnimation
            target: playerPage
            property: "y"
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    
    
    function switchQuality(qualityName) {
        
        var qualityUrl = twitchFetcher.getQualityUrl(qualityName)
        
        if (qualityUrl === "") {
            return
        }
        
        
        var wasPlaying = videoPlayer.playbackState === MediaPlayer.PlayingState
        
        videoPlayer.source = qualityUrl
        currentStreamUrl = qualityUrl
        currentQuality = qualityName
        
        if (wasPlaying) {
            videoPlayer.play()
        }
    }
    
    // Public function to start a stream
    function startStream(channel, quality) {
        
        channelName = channel
        requestedQuality = quality
        isActive = true
        state = "fullscreen"
        
        statusLabel.text = "Fetching stream..."
        statusOverlay.visible = true
        
        twitchFetcher.fetchStreamUrl(channel, quality)
    }
    
    // Signals for Main.qml
    signal playerMinimized()
    signal playerMaximized()
    signal playerClosed()
    
    // Connections to TwitchStreamFetcher
    Connections {
        target: twitchFetcher
        ignoreUnknownSignals: true
        
        onStreamUrlReady: {
            if (channelName === playerPage.channelName) {
                        currentStreamUrl = url
                statusLabel.text = "Starting playback..."
                videoPlayer.source = url
                videoPlayer.play()
                if (!isMiniMode) {
                    showControlsTemporarily()
                }
            }
        }
        
        onAvailableQualitiesChanged: {
                availableQualities.clear()
            
            for (var i = 0; i < qualities.length; i++) {
                availableQualities.append({ name: qualities[i] })
            }
            
            if (qualities.length > 0) {
                currentQuality = qualities[0]
            }
        }
        
        onError: {
                statusLabel.text = "Error: " + message
            statusOverlay.visible = true
        }
        
        onStatusUpdate: {
                statusLabel.text = status
            statusOverlay.visible = true
        }
    }
}
