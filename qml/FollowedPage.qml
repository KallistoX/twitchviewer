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
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import "components"

Page {
    id: followedPage
    objectName: "followedPage"

    property bool isRefreshing: false

    // Force the page to match StackView width
    width: StackView.view ? StackView.view.width : parent.width
    height: StackView.view ? StackView.view.height : parent.height

    onWidthChanged: {
        console.log("FollowedPage width changed:", width)
    }

    // Signal to request stream playback
    signal streamRequested(string channel, string quality)

    header: PageHeader {
        id: pageHeader
        title: i18n.tr('Followed Channels')
        
        leadingActionBar.actions: [
            Action {
                iconName: "navigation-menu"
                text: i18n.tr("Menu")
                onTriggered: root.toggleSidebar()
            }
        ]
        
        trailingActionBar.actions: [
            Action {
                iconName: "reload"
                text: i18n.tr("Refresh")
                enabled: !isRefreshing
                onTriggered: refreshFollowed()
            }
        ]
    }
    
    // Followed streams model
    ListModel {
        id: followedModel
    }
    
    // Pull to refresh with proper Flickable structure
    Flickable {
        id: mainFlickable
        anchors {
            top: pageHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        contentHeight: followedContent.height
        clip: true

        // Custom Pull to refresh
        CustomPullToRefresh {
            id: pullToRefresh
            target: mainFlickable
            refreshing: isRefreshing
            onRefresh: refreshFollowed()
        }

        Column {
            id: followedContent
            anchors {
                left: parent.left
                right: parent.right
            }
            spacing: units.gu(2)
            topPadding: pullToRefresh.height

                // Loading indicator (only show when refreshing but pull indicator is not visible)
                ActivityIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: isRefreshing && pullToRefresh.height === 0
                    visible: running
                }
                
                // Empty state
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: i18n.tr('No followed channels live right now')
                    visible: !isRefreshing && followedModel.count === 0
                    color: theme.palette.normal.backgroundSecondaryText
                }
                
                // Followed streams grid
                GridView {
                    id: followedGrid
                    width: parent.width
                    height: {
                        if (count === 0) return 0
                        var rows = Math.ceil(count / columnsCount)
                        return rows * cellHeight
                    }
                    
                    clip: true
                    interactive: false  // Let Flickable handle scrolling
                    model: followedModel
                    
                    // Responsive columns
                    property int columnsCount: {
                        if (width > units.gu(100)) return 4      // Wide landscape (tablet)
                        else if (width > units.gu(70)) return 3  // Landscape
                        else return 2                             // Portrait
                    }
                    
                    cellWidth: width / columnsCount
                    cellHeight: units.gu(32)
                    
                    delegate: Item {
                        width: followedGrid.cellWidth
                        height: followedGrid.cellHeight
                        
                        Rectangle {
                            anchors {
                                fill: parent
                                margins: units.gu(1)
                            }
                            color: theme.palette.normal.background
                            radius: units.gu(1)
                            
                            Column {
                                anchors.fill: parent
                                spacing: 0
                                clip: true
                                
                                // Thumbnail
                                Rectangle {
                                    width: parent.width
                                    height: parent.width * 9 / 16
                                    color: theme.palette.normal.base
                                    clip: true
                                    
                                    Image {
                                        anchors.fill: parent
                                        source: model.thumbnailUrl
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                    
                                    // LIVE badge and viewer count
                                    Row {
                                        anchors {
                                            left: parent.left
                                            top: parent.top
                                            margins: units.gu(0.5)
                                        }
                                        spacing: units.gu(0.5)
                                        
                                        Rectangle {
                                            width: liveLabel.width + units.gu(1)
                                            height: liveLabel.height + units.gu(0.5)
                                            color: "#e91916"
                                            radius: units.gu(0.5)
                                            
                                            Label {
                                                id: liveLabel
                                                anchors.centerIn: parent
                                                text: "LIVE"
                                                color: "white"
                                                font.bold: true
                                                fontSize: "x-small"
                                            }
                                        }
                                        
                                        Rectangle {
                                            width: viewerLabel.width + units.gu(1)
                                            height: viewerLabel.height + units.gu(0.5)
                                            color: Qt.rgba(0, 0, 0, 0.7)
                                            radius: units.gu(0.5)
                                            
                                            Label {
                                                id: viewerLabel
                                                anchors.centerIn: parent
                                                text: "👁️ " + model.viewerCountFormatted
                                                color: "white"
                                                fontSize: "x-small"
                                            }
                                        }
                                    }
                                }
                                
                                // Stream info
                                Column {
                                    width: parent.width
                                    padding: units.gu(1)
                                    spacing: units.gu(0.5)
                                    clip: true
                                    
                                    Label {
                                        width: parent.width - units.gu(2)
                                        text: model.title
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        fontSize: "small"
                                        font.bold: true
                                        clip: true
                                    }
                                    
                                    Label {
                                        width: parent.width - units.gu(2)
                                        text: model.userName
                                        elide: Text.ElideRight
                                        fontSize: "small"
                                        color: theme.palette.normal.backgroundSecondaryText
                                        clip: true
                                    }
                                    
                                    Label {
                                        width: parent.width - units.gu(2)
                                        text: model.gameName
                                        elide: Text.ElideRight
                                        fontSize: "x-small"
                                        color: theme.palette.normal.backgroundSecondaryText
                                        clip: true
                                    }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                                        watchStream(model.userLogin)
                                }
                            }
                        }
                    }
                }
            }
        }
    
    // Functions
    function refreshFollowed() {
        if (!authManager.isAuthenticated) {
            return
        }
        
        if (!twitchFetcher.hasUserInfo) {
            return
        }
        
        isRefreshing = true
        helixApi.getFollowedStreams(twitchFetcher.currentUserId, 100)
    }
    
    function watchStream(channelName) {
        streamRequested(channelName, "best")
    }
    
    // Load followed streams on component completion
    Component.onCompleted: {
        console.log("FollowedPage created | width:", width)

        if (authManager.isAuthenticated && twitchFetcher.hasUserInfo) {
            refreshFollowed()
        }
    }
    
    // Connections
    Connections {
        target: helixApi
        ignoreUnknownSignals: true
        
        onFollowedStreamsReceived: {
                followedModel.clear()
            
            for (var i = 0; i < streams.length; i++) {
                var stream = streams[i]
                
                var thumbnailUrl = stream.thumbnail_url
                thumbnailUrl = thumbnailUrl.replace("{width}", "440")
                thumbnailUrl = thumbnailUrl.replace("{height}", "248")
                
                var viewerCount = stream.viewer_count
                var viewerCountFormatted = viewerCount >= 1000 ? 
                    (viewerCount / 1000).toFixed(1) + "K" : 
                    viewerCount.toString()
                
                followedModel.append({
                    userLogin: stream.user_login,
                    userName: stream.user_name,
                    gameName: stream.game_name,
                    title: stream.title,
                    viewerCount: viewerCount,
                    viewerCountFormatted: viewerCountFormatted,
                    thumbnailUrl: thumbnailUrl
                })
            }
            
            isRefreshing = false
            }
        
        onError: {
                isRefreshing = false
        }
    }
    
    Connections {
        target: twitchFetcher
        ignoreUnknownSignals: true
        
        onCurrentUserChanged: {
            // When user info is loaded, fetch followed streams
            if (twitchFetcher.hasUserInfo && followedModel.count === 0) {
                        refreshFollowed()
            }
        }
    }
}
