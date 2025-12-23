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
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'twitchviewer.kallisto-app'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)
    
    Component.onCompleted: {
        console.log("MainView loaded")
        console.log("twitchFetcher exists:", typeof twitchFetcher !== 'undefined')
        if (typeof twitchFetcher !== 'undefined') {
            console.log("twitchFetcher is valid")
        } else {
            console.error("twitchFetcher is NOT available!")
        }
    }

    // Connections to TwitchStreamFetcher signals
    Connections {
        target: twitchFetcher
    ignoreUnknownSignals: true
        
    onStreamUrlReady: {
        console.log("QML received streamUrlReady signal")
        console.log("URL:", url)
        console.log("Channel:", channelName)
        statusLabel.text = "Starting playback..."
            videoPlayer.source = url
            videoPlayer.play()
        }
        
    onError: {
        console.error("QML received error signal:", message)
            statusLabel.text = "Error: " + message
            statusLabel.color = theme.palette.normal.negative
        }
        
    onStatusUpdate: {
        console.log("QML received statusUpdate signal:", status)
            statusLabel.text = status
            statusLabel.color = theme.palette.normal.backgroundSecondaryText
        }
    }

    Page {
        id: mainPage
        anchors.fill: parent

        header: PageHeader {
            id: header
            title: i18n.tr('TwitchViewer')
        }

        Flickable {
            id: flickable
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            contentHeight: contentColumn.height
            clip: true
            
            // Auto-scroll when keyboard appears
            property real keyboardHeight: Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0
            onKeyboardHeightChanged: {
                if (keyboardHeight > 0) {
                    contentY = Math.max(0, contentHeight - height + keyboardHeight)
                }
            }

            ColumnLayout {
                id: contentColumn
                spacing: units.gu(1)
                anchors {
                    margins: units.gu(1)
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                width: parent.width - units.gu(2)

                // Video Player Area
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: units.gu(40)
                    color: "black"

                    Video {
                        id: videoPlayer
                        anchors.fill: parent
                        autoPlay: false
                        
                        onStatusChanged: {
                            console.log("Video status:", status)
                            if (status === MediaPlayer.InvalidMedia) {
                                statusLabel.text = "Error: Invalid media"
                                statusLabel.color = theme.palette.normal.negative
                            } else if (status === MediaPlayer.NoMedia) {
                                statusLabel.text = i18n.tr('Enter a channel name to start')
        } else if (status === MediaPlayer.LoadedMedia) {
            console.log("Media loaded successfully")
                            }
                        }
                        
    // In QtMultimedia 5.8, use onErrorChanged instead of onError
    onErrorChanged: {
        if (error !== MediaPlayer.NoError) {
                            console.error("Video error:", errorString)
                            statusLabel.text = "Video error: " + errorString
                            statusLabel.color = theme.palette.normal.negative
                        }
                    }

                    }

                    // Status overlay
                    Label {
                        id: statusLabel
                        anchors.centerIn: parent
                        text: {
                            if (videoPlayer.playbackState === MediaPlayer.PlayingState)
                                return i18n.tr('Playing...')
                            else if (videoPlayer.playbackState === MediaPlayer.PausedState)
                                return i18n.tr('Paused')
                            else if (videoPlayer.status === MediaPlayer.Loading || videoPlayer.status === MediaPlayer.Buffering)
                                return i18n.tr('Loading...')
                            else
                                return i18n.tr('Enter a channel name to start')
                        }
                        color: "white"
                        visible: videoPlayer.playbackState !== MediaPlayer.PlayingState
                        font.pixelSize: units.gu(3)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        width: parent.width - units.gu(4)
                    }
                }

                // Channel Name Input
                TextField {
                    id: channelInput
                    Layout.fillWidth: true
                    placeholderText: i18n.tr('Enter Twitch channel name (e.g. esl_csgo)')
                    text: ""
                    
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhUrlCharactersOnly
                    
                    onAccepted: {
                        if (text.length > 0) {
                            statusLabel.text = "Fetching stream..."
                            twitchFetcher.fetchStreamUrl(text, "best")
                        }
                    }
                    
                    onActiveFocusChanged: {
                        if (activeFocus) {
                            flickable.contentY = Math.max(0, y - units.gu(5))
                        }
                    }
                }

                // Quality selector
                RowLayout {
                    Layout.fillWidth: true
                    spacing: units.gu(1)

                    Label {
                        text: i18n.tr('Quality:')
                        Layout.preferredWidth: units.gu(10)
                    }

                    ComboBox {
                        id: qualitySelector
                        Layout.fillWidth: true
                        model: ["Best (Auto)", "Source (1080p)", "High (720p)", "Medium (480p)", "Low (360p)"]
                        currentIndex: 0
                        
                        property var qualityValues: ["best", "source", "high", "medium", "low"]
                        property string selectedQuality: qualityValues[currentIndex]
                    }
                }

                // Control Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: units.gu(1)

                    Button {
                        Layout.fillWidth: true
                        text: i18n.tr('Watch Stream')
                        color: theme.palette.normal.positive
                        enabled: channelInput.text.length > 0
                        onClicked: {
                            statusLabel.text = "Fetching stream..."
                            twitchFetcher.fetchStreamUrl(channelInput.text, qualitySelector.selectedQuality)
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: videoPlayer.playbackState === MediaPlayer.PlayingState ? i18n.tr('Pause') : i18n.tr('Resume')
                        enabled: videoPlayer.source != ""
                        onClicked: {
                            if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
                                videoPlayer.pause()
                            } else {
                                videoPlayer.play()
                            }
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: i18n.tr('Stop')
                        color: theme.palette.normal.negative
                        enabled: videoPlayer.source != ""
                        onClicked: {
                            videoPlayer.stop()
                            statusLabel.text = i18n.tr('Enter a channel name to start')
                        }
                    }
                }

                // Quick Channel Buttons
                Label {
                    Layout.fillWidth: true
                    text: i18n.tr('Popular channels:')
                    fontSize: "small"
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: units.gu(1)

                    Button {
                        text: "esl_csgo"
                        onClicked: {
                            channelInput.text = "esl_csgo"
                            twitchFetcher.fetchStreamUrl("esl_csgo", qualitySelector.selectedQuality)
                        }
                    }

                    Button {
                        text: "chess"
                        onClicked: {
                            channelInput.text = "chess"
                            twitchFetcher.fetchStreamUrl("chess", qualitySelector.selectedQuality)
                        }
                    }

                    Button {
                        text: "nasa"
                        onClicked: {
                            channelInput.text = "nasa"
                            twitchFetcher.fetchStreamUrl("nasa", qualitySelector.selectedQuality)
                        }
                    }

                    Button {
                        text: "monstercat"
                        onClicked: {
                            channelInput.text = "monstercat"
                            twitchFetcher.fetchStreamUrl("monstercat", qualitySelector.selectedQuality)
                        }
                    }
                }

                // Info Label
                Label {
                    Layout.fillWidth: true
                    text: i18n.tr('Enter a Twitch channel name and press "Watch Stream" to start.\n\nYou can also try the popular channels above!')
                    wrapMode: Text.WordWrap
                    fontSize: "small"
                    color: theme.palette.normal.backgroundSecondaryText
                }
            }
        }
    }
}
