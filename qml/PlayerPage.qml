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

import QtQuick 2.7
import QtMultimedia 5.8
import QtQuick.Controls 2.2
import Lomiri.Components 1.3

Page {
    id: playerPage
    
    property string channelName: ""
    property string requestedQuality: "best"
    property string currentStreamUrl: ""
    property string currentQuality: "Best"
    
    // NO HEADER - Fullscreen!
    header: Item { height: 0 }
    
    ListModel {
        id: availableQualities
    }
    
    // Video player container (fullscreen)
    Rectangle {
        id: playerContainer
        anchors.fill: parent
        color: "black"
        
        Video {
            id: videoPlayer
            anchors.fill: parent
            autoPlay: false
            
            Component.onDestruction: {
                console.log("Video component being destroyed")
                if (playbackState === MediaPlayer.PlayingState) {
                    stop()
                }
            }
            
            onStatusChanged: {
                console.log("Video status:", status)
                if (status === MediaPlayer.InvalidMedia) {
                    statusLabel.text = "Error: Invalid media"
                    statusOverlay.visible = true
                } else if (status === MediaPlayer.NoMedia) {
                    statusLabel.text = i18n.tr('Loading stream...')
                    statusOverlay.visible = true
                } else if (status === MediaPlayer.LoadedMedia) {
                    console.log("Media loaded successfully")
                    statusOverlay.visible = false
                } else if (status === MediaPlayer.Loading || status === MediaPlayer.Buffering) {
                    statusLabel.text = i18n.tr('Buffering...')
                    statusOverlay.visible = true
                }
            }
            
            onErrorChanged: {
                if (error !== MediaPlayer.NoError) {
                    console.error("Video error:", errorString)
                    statusLabel.text = "Video error: " + errorString
                    statusOverlay.visible = true
                }
            }
            
            onPlaybackStateChanged: {
                console.log("Playback state:", playbackState)
                if (playbackState === MediaPlayer.PlayingState) {
                    statusOverlay.visible = false
                    showControlsTemporarily()
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
        
        // ALWAYS-VISIBLE tap area (must be outside controlsOverlay!)
        MouseArea {
            anchors.fill: parent
            onClicked: {
                console.log("Video tapped, controls opacity:", controlsOverlay.opacity)
                if (controlsOverlay.opacity > 0) {
                    hideControls()
                } else {
                    showControlsTemporarily()
                }
            }
        }
        
        // Controls overlay (auto-hide)
        Rectangle {
            id: controlsOverlay
            anchors.fill: parent
            color: "transparent"
            visible: opacity > 0
            opacity: 0
            
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
            
            // Top bar - Exit button (right)
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
                
                Icon {
                    anchors.centerIn: parent
                    name: "close"
                    width: units.gu(3)
                    height: units.gu(3)
                    color: "white"
                }
                
                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: false  // Don't propagate to background MouseArea
                    onClicked: {
                        console.log("Exiting player")
                        if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
                            videoPlayer.stop()
                        }
                        stackView.pop()
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
                    propagateComposedEvents: false  // Don't propagate to background MouseArea
                    onClicked: {
                        console.log("Play/Pause clicked")
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
                    propagateComposedEvents: false  // Don't propagate to background MouseArea
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
                color: theme.palette.normal.background
                radius: units.gu(1)
                border.color: theme.palette.normal.base
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
                            color: currentQuality === model.name ? theme.palette.normal.positive : "transparent"
                            
                            Label {
                                anchors {
                                    left: parent.left
                                    leftMargin: units.gu(1)
                                    verticalCenter: parent.verticalCenter
                                }
                                text: model.name
                                color: currentQuality === model.name ? "white" : theme.palette.normal.baseText
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    console.log("Switching to quality:", model.name)
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
    }
    
    // Auto-hide timer
    Timer {
        id: hideControlsTimer
        interval: 3000
        repeat: false
        onTriggered: hideControls()
    }
    
    // Functions
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
    
    function switchQuality(qualityName) {
        console.log("Switching quality to:", qualityName)
        
        var qualityUrl = twitchFetcher.getQualityUrl(qualityName)
        
        if (qualityUrl === "") {
            console.error("No URL found for quality:", qualityName)
            return
        }
        
        console.log("Quality URL:", qualityUrl.substring(0, 80) + "...")
        
        var wasPlaying = videoPlayer.playbackState === MediaPlayer.PlayingState
        
        videoPlayer.source = qualityUrl
        currentStreamUrl = qualityUrl
        currentQuality = qualityName
        
        if (wasPlaying) {
            videoPlayer.play()
        }
    }
    
    // Component lifecycle
    Component.onCompleted: {
        console.log("PlayerPage loaded for channel:", channelName)
        statusLabel.text = "Fetching stream..."
        statusOverlay.visible = true
        twitchFetcher.fetchStreamUrl(channelName, requestedQuality)
    }
    
    Component.onDestruction: {
        console.log("PlayerPage being destroyed")
        if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
            videoPlayer.stop()
        }
    }
    
    // Connections to TwitchStreamFetcher
    Connections {
        target: twitchFetcher
        ignoreUnknownSignals: true
        
        onStreamUrlReady: {
            if (channelName === playerPage.channelName) {
                console.log("Stream URL ready for", channelName)
                currentStreamUrl = url
                statusLabel.text = "Starting playback..."
                videoPlayer.source = url
                videoPlayer.play()
                showControlsTemporarily()
            }
        }
        
        onAvailableQualitiesChanged: {
            console.log("Available qualities:", qualities)
            availableQualities.clear()
            
            for (var i = 0; i < qualities.length; i++) {
                availableQualities.append({ name: qualities[i] })
            }
            
            if (qualities.length > 0) {
                currentQuality = qualities[0]
            }
        }
        
        onError: {
            console.error("Stream fetch error:", message)
            statusLabel.text = "Error: " + message
            statusOverlay.visible = true
        }
        
        onStatusUpdate: {
            console.log("Status update:", status)
            statusLabel.text = status
            statusOverlay.visible = true
        }
    }
}
