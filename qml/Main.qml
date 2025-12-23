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

    Page {
        id: mainPage
        anchors.fill: parent

        header: PageHeader {
            id: header
            title: i18n.tr('TwitchViewer')
        }
        
        // Hardcoded test URL - replace with your streamlink output
        property string testStreamUrl: "https://euc11.playlist.ttvnw.net/v1/playlist/CuoEXu6jIXeKXAKrIwrs2s4rb8Zgs3iMDaN2Fyb_sGe1wrPBbh_yBTi-_S4iZ3lLHB1tBFPAMzfW-YK-gBDswToRokySWzY3eytO5xfZGTl_TQiHDm4s_tfVZY1wTkyXmOHQUlvkPr68P_ZmTqvCUCesh8PaSTzDKPcBReAsFDT4O5LrOAm7LynuBZnvIxEfSfz8eVU35xm82S_1mlj7S585sfOFnw5zypSq8QlXeeIJg8ysoCpceoqgw4d-vgGkfZcsRez3-FN2LinkT1NBOMfwIneMXkT0ahiNGj7r5-WZ63y3Ig4T5byrO7ssRU9kyfo3G0hNZzPqLhng7fdnZtf6927W1yy61bgXTZAbOmGeYy6V0QlJChYAoZYFmznkWMxviX8YvklQ4rtIjIeyqWuHajck3f87AigtPtyZD1iHaOt-5HPMG7iOxLwqf4yvDFFWxGyfqWJ13zKbUBcELssnQHoQ7QqVKpfcahzqM1xmaYqzplVsD1dz_BXyTHS1o66QYpsDqeiAIKGA8COSKHRKY4poIYzzA8iTjTcqcJhRWCsVjRnddfpjynxOO9gRWk7BAmgnGbLGvIFS3eZ_XcJojelJ7N7LXYDwMx4g5VYxr9iOhVqmLLLNUJiDSQ5ILWUwBH4VxphS0WhnwvmOa1o8t149Jh4Cg9gUWye7SnOzqotG-hyOlzIFKoZoGeAP5-iWJX0TqJKwT45Sl8yCVHQlzWkziBRt7Jyj6FzJDa45-3KZLjfZoGRdRza6xkOyOToMwJkkIfgpznGfwZ3p_6ZiA4be0YRfGBqldfRClmVrCyaz-cCqgJdL-fYHGgxlDKbCkrTWFR1cioIgASoJZXUtd2VzdC0yMIIO.m3u8"

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
                    // Scroll to show the text field
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
                            } else if (status === MediaPlayer.NoMedia) {
                                statusLabel.text = "Ready"
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
                                return i18n.tr('Ready')
                        }
                        color: "white"
                        visible: videoPlayer.playbackState !== MediaPlayer.PlayingState
                        font.pixelSize: units.gu(3)
                    }
                }

                // URL Input
                TextField {
                    id: urlInput
                    Layout.fillWidth: true
                    placeholderText: i18n.tr('Enter direct video URL...')
                    text: ""
                    
                    // Disable autocorrect and predictive text for URLs
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhUrlCharactersOnly
                    
                    onAccepted: {
                        if (text.length > 0) {
                            videoPlayer.source = text
                            videoPlayer.play()
                        }
                    }
                    
                    // Focus handling
                    onActiveFocusChanged: {
                        if (activeFocus) {
                            flickable.contentY = Math.max(0, y - units.gu(5))
                        }
                    }
                }

                // Test Button for hardcoded Twitch stream
                Button {
                    Layout.fillWidth: true
                    text: i18n.tr('🧪 Test Twitch Stream')
                    color: theme.palette.normal.activity
                    visible: mainPage.testStreamUrl !== "PASTE_YOUR_M3U8_URL_HERE"
                    onClicked: {
                        urlInput.text = mainPage.testStreamUrl
                        videoPlayer.source = mainPage.testStreamUrl
                        videoPlayer.play()
                    }
                }

                // Control Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: units.gu(1)

                    Button {
                        Layout.fillWidth: true
                        text: i18n.tr('Play')
                        color: theme.palette.normal.positive
                        onClicked: {
                            if (urlInput.text.length > 0 && videoPlayer.source != urlInput.text) {
                                videoPlayer.source = urlInput.text
                            }
                            videoPlayer.play()
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: i18n.tr('Pause')
                        onClicked: videoPlayer.pause()
                    }

                    Button {
                        Layout.fillWidth: true
                        text: i18n.tr('Stop')
                        color: theme.palette.normal.negative
                        onClicked: videoPlayer.stop()
                    }
                }

                // Info Label
                Label {
                    Layout.fillWidth: true
                    text: {
                        if (mainPage.testStreamUrl === "PASTE_YOUR_M3U8_URL_HERE") {
                            return i18n.tr('To test Twitch:\n1. Run: streamlink https://twitch.tv/CHANNEL best --stream-url\n2. Edit Main.qml: Replace testStreamUrl with the m3u8 URL\n3. Rebuild and click the Test button\n\nOr use direct video URLs like:\nhttp://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4')
                        } else {
                            return i18n.tr('🧪 Test button loaded with Twitch stream! Click to play.\n\nOr enter any direct video URL (MP4, M3U8).')
                        }
                    }
                    wrapMode: Text.WordWrap
                    fontSize: "small"
                    color: theme.palette.normal.backgroundSecondaryText
                }
            }
        }
    }
}
