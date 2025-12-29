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
        console.log("authManager exists:", typeof authManager !== 'undefined')
        console.log("helixApi exists:", typeof helixApi !== 'undefined')
        
        // FIXED: Only fetch user info ONCE, and only if we have GraphQL token
        // (Constructor no longer auto-fetches)
        if (typeof twitchFetcher !== 'undefined' && twitchFetcher.hasGraphQLToken) {
            console.log("GraphQL token found, fetching user info once...")
            twitchFetcher.fetchCurrentUser()
        }
        
        // Load top games (will use OAuth token if available, otherwise anonymous)
        if (typeof helixApi !== 'undefined') {
            console.log("Loading top games...")
            helixApi.getTopGames(20)
        }
    }

    Component.onDestruction: {
        console.log("MainView being destroyed")
    }

    PageStack {
        id: pageStack
        anchors.fill: parent
        
        Component.onCompleted: push(homePage)
        
        // ========================================
        // HOME PAGE (Main browse/channel selection)
        // ========================================
        
        Component {
            id: homePage
            
            Page {
                id: homePageItem
                
                header: PageHeader {
                    id: homeHeader
                    title: i18n.tr('TwitchViewer')
                    
                    trailingActionBar.actions: [
                        Action {
                            iconName: "settings"
                            text: i18n.tr("Settings")
                            onTriggered: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
                        }
                    ]
                }

                // Auth Status Bar
                Rectangle {
                    id: authStatusBar
                    anchors {
                        top: homeHeader.bottom
                        left: parent.left
                        right: parent.right
                    }
                    height: authStatusContent.height + units.gu(1)
                    color: theme.palette.normal.background
                    visible: twitchFetcher.hasGraphQLToken || authManager.isAuthenticated
                    
                    Row {
                        id: authStatusContent
                        anchors {
                            margins: units.gu(1)
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: units.gu(1)
                        
                        // Profile Image (if available)
                        Rectangle {
                            width: units.gu(5)
                            height: units.gu(5)
                            radius: width / 2
                            color: theme.palette.normal.base
                            visible: twitchFetcher.hasUserInfo
                            clip: true
                            
                            Image {
                                anchors.centerIn: parent
                                width: parent.width
                                height: parent.height
                                source: twitchFetcher.currentUserProfileImage
                                fillMode: Image.PreserveAspectCrop
                                visible: source != ""
                                smooth: true
                                
                                onStatusChanged: {
                                    if (status === Image.Error) {
                                        console.error("Failed to load profile image:", source)
                                    } else if (status === Image.Ready) {
                                        console.log("✅ Profile image loaded successfully")
                                    }
                                }
                            }
                            
                            Icon {
                                anchors.centerIn: parent
                                name: "contact"
                                width: units.gu(3)
                                height: units.gu(3)
                                visible: twitchFetcher.currentUserProfileImage == ""
                            }
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: units.gu(0.5)
                            width: parent.width - units.gu(7)
                            
                            // User info (if available)
                            Label {
                                text: twitchFetcher.currentUserDisplayName
                                font.bold: true
                                visible: twitchFetcher.hasUserInfo
                            }
                            
                            Label {
                                text: "@" + twitchFetcher.currentUserLogin
                                fontSize: "small"
                                color: theme.palette.normal.backgroundSecondaryText
                                visible: twitchFetcher.hasUserInfo
                            }
                            
                            // Token status
                            Row {
                                spacing: units.gu(0.5)
                                
                                // GraphQL Token status
                                Rectangle {
                                    width: statusRow1.width + units.gu(1)
                                    height: statusRow1.height + units.gu(0.5)
                                    radius: units.gu(0.5)
                                    color: twitchFetcher.hasGraphQLToken ? theme.palette.normal.positive : theme.palette.normal.base
                                    
                                    Row {
                                        id: statusRow1
                                        anchors.centerIn: parent
                                        spacing: units.gu(0.5)
                                        
                                        Icon {
                                            name: twitchFetcher.hasGraphQLToken ? "tick" : "close"
                                            width: units.gu(1.5)
                                            height: units.gu(1.5)
                                            color: twitchFetcher.hasGraphQLToken ? "white" : theme.palette.normal.backgroundSecondaryText
                                        }
                                        
                                        Label {
                                            text: "Ad-Free"
                                            fontSize: "x-small"
                                            color: twitchFetcher.hasGraphQLToken ? "white" : theme.palette.normal.backgroundSecondaryText
                                        }
                                    }
                                }
                                
                                // OAuth status
                                Rectangle {
                                    width: statusRow2.width + units.gu(1)
                                    height: statusRow2.height + units.gu(0.5)
                                    radius: units.gu(0.5)
                                    color: authManager.isAuthenticated ? theme.palette.normal.positive : theme.palette.normal.base
                                    
                                    Row {
                                        id: statusRow2
                                        anchors.centerIn: parent
                                        spacing: units.gu(0.5)
                                        
                                        Icon {
                                            name: authManager.isAuthenticated ? "tick" : "close"
                                            width: units.gu(1.5)
                                            height: units.gu(1.5)
                                            color: authManager.isAuthenticated ? "white" : theme.palette.normal.backgroundSecondaryText
                                        }
                                        
                                        Label {
                                            text: "OAuth"
                                            fontSize: "x-small"
                                            color: authManager.isAuthenticated ? "white" : theme.palette.normal.backgroundSecondaryText
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Flickable {
                    id: flickable
                    anchors {
                        top: authStatusBar.visible ? authStatusBar.bottom : homeHeader.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    contentHeight: contentColumn.height
                    clip: true
                    
                    ColumnLayout {
                        id: contentColumn
                        spacing: units.gu(2)
                        anchors {
                            margins: units.gu(2)
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        width: parent.width - units.gu(4)

                        // ========================================
                        // MANUAL CHANNEL INPUT
                        // ========================================
                        
                        Label {
                            text: i18n.tr('Watch a Stream')
                            font.bold: true
                            fontSize: "large"
                            Layout.fillWidth: true
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: units.gu(1)
                            
                            TextField {
                                id: channelInput
                                Layout.fillWidth: true
                                placeholderText: i18n.tr('Enter channel name (e.g. esl_csgo)')
                                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhUrlCharactersOnly
                                
                                onAccepted: {
                                    if (text.length > 0) {
                                        watchStream(text, "best")
                                    }
                                }
                            }
                            
                            Button {
                                text: i18n.tr('Watch')
                                color: theme.palette.normal.positive
                                enabled: channelInput.text.length > 0
                                onClicked: {
                                    watchStream(channelInput.text, "best")
                                }
                            }
                        }
                        
                        // Quick channel buttons
                        Flow {
                            Layout.fillWidth: true
                            spacing: units.gu(1)
                            
                            Label {
                                text: i18n.tr('Popular:')
                                fontSize: "small"
                                width: parent.width
                            }

                            Button {
                                text: "esl_csgo"
                                onClicked: watchStream("esl_csgo", "best")
                            }

                            Button {
                                text: "chess"
                                onClicked: watchStream("chess", "best")
                            }

                            Button {
                                text: "nasa"
                                onClicked: watchStream("nasa", "best")
                            }

                            Button {
                                text: "monstercat"
                                onClicked: watchStream("monstercat", "best")
                            }
                        }

                        // ========================================
                        // TOP CATEGORIES
                        // ========================================
                        
                        Label {
                            text: i18n.tr('Top Categories')
                            font.bold: true
                            fontSize: "large"
                            Layout.fillWidth: true
                        }
                        
                        // Category list
                        ListModel {
                            id: categoryModel
                        }
                        
                        GridView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: units.gu(30)
                            cellWidth: units.gu(15)
                            cellHeight: units.gu(25)
                            clip: true
                            model: categoryModel
                            
                            delegate: Rectangle {
                                width: units.gu(14)
                                height: units.gu(24)
                                color: "transparent"
                                
                                Column {
                                    anchors.centerIn: parent
                                    spacing: units.gu(1)
                                    width: parent.width
                                    
                                    Rectangle {
                                        width: units.gu(12)
                                        height: units.gu(16)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: theme.palette.normal.base
                                        radius: units.gu(1)
                                        
                                        Image {
                                            anchors.fill: parent
                                            source: model.boxArtUrl
                                            fillMode: Image.PreserveAspectFit
                                        }
                                        
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                console.log("Category clicked:", model.name)
                                                // TODO: Show streams for this category
                                            }
                                        }
                                    }
                                    
                                    Label {
                                        text: model.name
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                        fontSize: "small"
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                        
                        Label {
                            text: categoryModel.count === 0 ? i18n.tr('Loading categories...') : ""
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            color: theme.palette.normal.backgroundSecondaryText
                            visible: categoryModel.count === 0
                        }
                    }
                }
                
                // Helper function to start watching a stream
                function watchStream(channelName, quality) {
                    console.log("Starting stream:", channelName, "quality:", quality)
                    pageStack.push(playerPage, {
                        channelName: channelName,
                        requestedQuality: quality
                    })
                }
                
                // Helix API connections - MUST be inside homePage to access categoryModel
                Connections {
                    target: helixApi
                    ignoreUnknownSignals: true
                    
                    onTopGamesReceived: {
                        console.log("Top games received:", games.length)
                        categoryModel.clear()
                        
                        for (var i = 0; i < games.length; i++) {
                            var game = games[i]
                            var boxArtUrl = game.box_art_url
                            // Replace placeholders with actual dimensions
                            boxArtUrl = boxArtUrl.replace("{width}", "285")
                            boxArtUrl = boxArtUrl.replace("{height}", "380")
                            
                            categoryModel.append({
                                id: game.id,
                                name: game.name,
                                boxArtUrl: boxArtUrl
                            })
                        }
                        
                        console.log("Category model populated with", categoryModel.count, "items")
                    }
                    
                    onError: {
                        console.error("Helix API error:", message)
                    }
                }
            }
        }
        
        // ========================================
        // PLAYER PAGE (Fullscreen video)
        // ========================================
        
        Component {
            id: playerPage
            
            Page {
                id: playerPageItem
                
                property string channelName: ""
                property string requestedQuality: "best"
                property string currentStreamUrl: ""
                property string currentQuality: "Best"
                
                ListModel {
                    id: availableQualities
                }
                
                function switchQuality(qualityName) {
                    console.log("Switching quality to:", qualityName)
                    
                    // Get URL for this quality
                    var qualityUrl = twitchFetcher.getQualityUrl(qualityName)
                    
                    if (qualityUrl === "") {
                        console.error("No URL found for quality:", qualityName)
                        return
                    }
                    
                    console.log("Quality URL:", qualityUrl.substring(0, 80) + "...")
                    
                    // Remember current position
                    var wasPlaying = videoPlayer.playbackState === MediaPlayer.PlayingState
                    
                    // Switch source
                    videoPlayer.source = qualityUrl
                    currentStreamUrl = qualityUrl
                    currentQuality = qualityName
                    
                    // Resume if was playing
                    if (wasPlaying) {
                        videoPlayer.play()
                    }
                }
                
                header: PageHeader {
                    id: playerHeader
                    title: channelName
                    
                    leadingActionBar.actions: [
                        Action {
                            iconName: "back"
                            text: i18n.tr("Back")
                            onTriggered: {
                                console.log("Stopping video and going back")
                                if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
                                    videoPlayer.stop()
                                }
                                pageStack.pop()
                            }
                        }
                    ]
                    
                    trailingActionBar.actions: [
                        Action {
                            iconName: videoPlayer.playbackState === MediaPlayer.PlayingState ? "media-playback-pause" : "media-playback-start"
                            text: videoPlayer.playbackState === MediaPlayer.PlayingState ? i18n.tr("Pause") : i18n.tr("Play")
                            enabled: videoPlayer.source != ""
                            onTriggered: {
                                if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
                                    videoPlayer.pause()
                                } else {
                                    videoPlayer.play()
                                }
                            }
                        }
                    ]
                }
                
                Component.onCompleted: {
                    console.log("PlayerPage loaded for channel:", channelName)
                    statusLabel.text = "Fetching stream..."
                    twitchFetcher.fetchStreamUrl(channelName, requestedQuality)
                }
                
                Component.onDestruction: {
                    console.log("PlayerPage being destroyed - stopping video")
                    if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
                        videoPlayer.stop()
                    }
                }
                
                // Video player (fullscreen)
                Rectangle {
                    id: playerContainer
                    anchors {
                        top: playerHeader.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
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
                                statusLabel.color = theme.palette.normal.negative
                            } else if (status === MediaPlayer.NoMedia) {
                                statusLabel.text = i18n.tr('Loading stream...')
                            } else if (status === MediaPlayer.LoadedMedia) {
                                console.log("Media loaded successfully")
                                statusLabel.text = ""
                            } else if (status === MediaPlayer.Loading || status === MediaPlayer.Buffering) {
                                statusLabel.text = i18n.tr('Buffering...')
                            }
                        }
                        
                        onErrorChanged: {
                            if (error !== MediaPlayer.NoError) {
                                console.error("Video error:", errorString)
                                statusLabel.text = "Video error: " + errorString
                                statusLabel.color = theme.palette.normal.negative
                            }
                        }
                        
                        onPlaybackStateChanged: {
                            console.log("Playback state:", playbackState)
                        }
                    }

                    // Status overlay
                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: 0.8
                        visible: statusLabel.visible
                        
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
                                visible: videoPlayer.playbackState !== MediaPlayer.PlayingState || text.length > 0
                                font.pixelSize: units.gu(2)
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }
                    
                    // Quality selector button (bottom right)
                    Rectangle {
                        id: qualityButton
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                            margins: units.gu(2)
                        }
                        width: units.gu(12)
                        height: units.gu(4)
                        color: theme.palette.normal.background
                        opacity: 0.9
                        radius: units.gu(0.5)
                        visible: availableQualities.count > 0 && videoPlayer.playbackState === MediaPlayer.PlayingState
                        
                        Label {
                            anchors.centerIn: parent
                            text: currentQuality
                            font.bold: true
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: qualityPopup.visible = !qualityPopup.visible
                        }
                    }
                    
                    // Quality popup menu
                    Rectangle {
                        id: qualityPopup
                        anchors {
                            right: qualityButton.right
                            bottom: qualityButton.top
                            bottomMargin: units.gu(1)
                        }
                        width: units.gu(20)
                        height: Math.min(qualityList.contentHeight + units.gu(2), playerContainer.height * 0.6)
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
                            
                            Label {
                                text: i18n.tr("Quality")
                                font.bold: true
                                width: parent.width
                            }
                            
                            ListView {
                                id: qualityList
                                width: parent.width
                                height: parent.height - units.gu(4)
                                clip: true
                                model: availableQualities
                                
                                delegate: Rectangle {
                                    width: parent.width
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
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Connections to TwitchStreamFetcher
                Connections {
                    target: twitchFetcher
                    ignoreUnknownSignals: true
                    
                    onStreamUrlReady: {
                        if (channelName === playerPageItem.channelName) {
                            console.log("Stream URL ready for", channelName)
                            currentStreamUrl = url
                            statusLabel.text = "Starting playback..."
                            videoPlayer.source = url
                            videoPlayer.play()
                        }
                    }
                    
                    onAvailableQualitiesChanged: {
                        console.log("Available qualities:", qualities)
                        availableQualities.clear()
                        
                        for (var i = 0; i < qualities.length; i++) {
                            availableQualities.append({ name: qualities[i] })
                        }
                        
                        // Set initial quality label
                        if (qualities.length > 0) {
                            currentQuality = qualities[0]
                        }
                    }
                    
                    onError: {
                        console.error("Stream fetch error:", message)
                        statusLabel.text = "Error: " + message
                        statusLabel.color = theme.palette.normal.negative
                    }
                    
                    onStatusUpdate: {
                        console.log("Status update:", status)
                        statusLabel.text = status
                        statusLabel.color = theme.palette.normal.backgroundSecondaryText
                    }
                }
            }
        }
    }
    
    // User info updates
    Connections {
        target: twitchFetcher
        ignoreUnknownSignals: true
        
        onCurrentUserChanged: {
            console.log("User info changed")
            if (twitchFetcher.hasUserInfo) {
                console.log("  Display Name:", twitchFetcher.currentUserDisplayName)
                console.log("  Login:", twitchFetcher.currentUserLogin)
                console.log("  Profile Image:", twitchFetcher.currentUserProfileImage)
            }
        }
    }
}
