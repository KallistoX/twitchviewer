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
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

import TwitchPlayer 1.0

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'twitchviewer.kallisto-app'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    Page {
        anchors.fill: parent

        header: PageHeader {
            id: header
            title: i18n.tr('TwitchViewer')
        }

        ColumnLayout {
            spacing: units.gu(1)
            anchors {
                margins: units.gu(1)
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            // Video Player Area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "black"

                MpvPlayer {
                    id: videoPlayer
                    anchors.fill: parent
                }

                // Status overlay
                Label {
                    anchors.centerIn: parent
                    text: videoPlayer.playing ? i18n.tr('Playing...') : i18n.tr('Ready')
                    color: "white"
                    visible: !videoPlayer.playing
                    font.pixelSize: units.gu(3)
                }
            }

            // URL Input
            TextField {
                id: urlInput
                Layout.fillWidth: true
                placeholderText: i18n.tr('Enter stream URL or Twitch channel name...')
                text: ""
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
                        if (urlInput.text.length > 0) {
                            // For now, just pass the URL directly
                            // Later we'll add streamlink integration for Twitch URLs
                            videoPlayer.source = urlInput.text
                            videoPlayer.play()
                        }
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
                text: i18n.tr('Test with a direct video URL (e.g., http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4)')
                wrapMode: Text.WordWrap
                fontSize: "small"
                color: theme.palette.normal.backgroundSecondaryText
            }
        }
    }
}
