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
import QtQuick.Controls 2.2
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3

Page {
    id: followedPage
    
    property bool isRefreshing: false
    
    header: PageHeader {
        id: pageHeader
        title: i18n.tr('Followed Channels')
        
        leadingActionBar.actions: [
            Action {
                iconName: "navigation-menu"
                text: i18n.tr("Menu")
                onTriggered: drawer.open()
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
    
    // Pull to refresh
    PullToRefresh {
        id: pullToRefresh
        anchors {
            top: pageHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        refreshing: isRefreshing
        
        onRefresh: refreshFollowed()
        
        Flickable {
            anchors.fill: parent
            contentHeight: followedContent.height
            
            Column {
                id: followedContent
                width: parent.width
                spacing: units.gu(2)
                
                // Loading indicator
                ActivityIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: isRefreshing
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
                                    console.log("Starting stream:", model.userLogin)
                                    watchStream(model.userLogin)
                                }
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
            console.log("Cannot refresh followed streams: not authenticated")
            return
        }
        
        if (!twitchFetcher.hasUserInfo) {
            console.log("Cannot refresh followed streams: no user info")
            return
        }
        
        console.log("Refreshing followed streams...")
        isRefreshing = true
        helixApi.getFollowedStreams(twitchFetcher.currentUserId, 100)
    }
    
    function watchStream(channelName) {
        stackView.push(playerPage, {
            channelName: channelName,
            requestedQuality: "best"
        })
    }
    
    // Load followed streams on component completion
    Component.onCompleted: {
        console.log("FollowedPage loaded")
        if (authManager.isAuthenticated && twitchFetcher.hasUserInfo) {
            refreshFollowed()
        }
    }
    
    // Connections
    Connections {
        target: helixApi
        ignoreUnknownSignals: true
        
        onFollowedStreamsReceived: {
            console.log("Followed streams received:", streams.length)
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
            console.log("Followed model populated with", followedModel.count, "items")
        }
        
        onError: {
            console.error("Helix API error:", message)
            isRefreshing = false
        }
    }
    
    Connections {
        target: twitchFetcher
        ignoreUnknownSignals: true
        
        onCurrentUserChanged: {
            // When user info is loaded, fetch followed streams
            if (twitchFetcher.hasUserInfo && followedModel.count === 0) {
                console.log("User info loaded, fetching followed streams...")
                refreshFollowed()
            }
        }
    }
}
