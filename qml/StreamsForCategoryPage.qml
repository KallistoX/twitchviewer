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
    id: streamsForCategoryPage
    
    // Properties passed from CategoriesPage
    property string categoryId: ""
    property string categoryName: ""
    
    property bool isRefreshing: false
    property bool isLoadingMore: false
    property string paginationCursor: ""
    property bool hasMorePages: false
    
    header: PageHeader {
        id: pageHeader
        title: categoryName
        
        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: i18n.tr("Back")
                onTriggered: stackView.pop()
            }
        ]
        
        trailingActionBar.actions: [
            Action {
                iconName: "reload"
                text: i18n.tr("Refresh")
                enabled: !isRefreshing
                onTriggered: refreshStreams()
            }
        ]
    }
    
    // Streams model
    ListModel {
        id: streamsModel
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
        
        onRefresh: refreshStreams()
        
        Flickable {
            anchors.fill: parent
            contentHeight: streamsContent.height
            
            Column {
                id: streamsContent
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
                    text: i18n.tr('No streams online for this category')
                    visible: !isRefreshing && streamsModel.count === 0
                    color: theme.palette.normal.backgroundSecondaryText
                }
                
                // Streams grid
                GridView {
                    id: streamsGrid
                    width: parent.width
                    height: {
                        if (count === 0) return 0
                        var rows = Math.ceil(count / columnsCount)
                        return rows * cellHeight
                    }
                    
                    clip: true
                    interactive: false  // Let Flickable handle scrolling
                    model: streamsModel
                    
                    // Responsive columns
                    property int columnsCount: {
                        if (width > units.gu(100)) return 4      // Wide landscape (tablet)
                        else if (width > units.gu(70)) return 3  // Landscape
                        else return 2                             // Portrait
                    }
                    
                    cellWidth: width / columnsCount
                    cellHeight: units.gu(32)
                    
                    delegate: Item {
                        width: streamsGrid.cellWidth
                        height: streamsGrid.cellHeight
                        
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
                
                // Load More button
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: i18n.tr('Load More')
                    visible: hasMorePages && !isLoadingMore && streamsModel.count > 0
                    onClicked: loadMoreStreams()
                }
                
                // Loading More indicator
                ActivityIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: isLoadingMore
                    visible: running
                }
            }
        }
    }
    
    // Functions
    function refreshStreams() {
        console.log("Refreshing streams for category:", categoryId)
        isRefreshing = true
        paginationCursor = ""
        helixApi.getStreamsForGame(categoryId, 20)
    }
    
    function loadMoreStreams() {
        if (!hasMorePages || isLoadingMore) return
        
        console.log("Loading more streams, cursor:", paginationCursor)
        isLoadingMore = true
        
        // Use helixApi with pagination cursor
        // Note: We need to add a method that supports pagination
        // For now, we'll just load the next page manually
        helixApi.getStreamsForGameWithCursor(categoryId, 20, paginationCursor)
    }
    
    function watchStream(channelName) {
        stackView.push(playerPage, {
            channelName: channelName,
            requestedQuality: "best"
        })
    }
    
    // Load streams on component completion
    Component.onCompleted: {
        console.log("StreamsForCategoryPage loaded for:", categoryName, "ID:", categoryId)
        if (categoryId.length > 0) {
            refreshStreams()
        }
    }
    
    // Connections
    Connections {
        target: helixApi
        ignoreUnknownSignals: true
        
        onStreamsReceived: {
            console.log("Streams received:", streams.length)
            
            // If refreshing, clear model. If loading more, append
            if (isRefreshing) {
                streamsModel.clear()
            }
            
            for (var i = 0; i < streams.length; i++) {
                var stream = streams[i]
                
                var thumbnailUrl = stream.thumbnail_url
                thumbnailUrl = thumbnailUrl.replace("{width}", "440")
                thumbnailUrl = thumbnailUrl.replace("{height}", "248")
                
                var viewerCount = stream.viewer_count
                var viewerCountFormatted = viewerCount >= 1000 ? 
                    (viewerCount / 1000).toFixed(1) + "K" : 
                    viewerCount.toString()
                
                streamsModel.append({
                    userLogin: stream.user_login,
                    userName: stream.user_name,
                    title: stream.title,
                    viewerCount: viewerCount,
                    viewerCountFormatted: viewerCountFormatted,
                    thumbnailUrl: thumbnailUrl
                })
            }
            
            isRefreshing = false
            isLoadingMore = false
            
            console.log("Streams model now has", streamsModel.count, "items")
        }
        
        onStreamsPaginationReceived: {
            console.log("Streams with pagination received:", streams.length)
            console.log("Pagination cursor:", cursor)
            
            // If refreshing, clear model. If loading more, append
            if (isRefreshing) {
                streamsModel.clear()
            }
            
            for (var i = 0; i < streams.length; i++) {
                var stream = streams[i]
                
                var thumbnailUrl = stream.thumbnail_url
                thumbnailUrl = thumbnailUrl.replace("{width}", "440")
                thumbnailUrl = thumbnailUrl.replace("{height}", "248")
                
                var viewerCount = stream.viewer_count
                var viewerCountFormatted = viewerCount >= 1000 ? 
                    (viewerCount / 1000).toFixed(1) + "K" : 
                    viewerCount.toString()
                
                streamsModel.append({
                    userLogin: stream.user_login,
                    userName: stream.user_name,
                    title: stream.title,
                    viewerCount: viewerCount,
                    viewerCountFormatted: viewerCountFormatted,
                    thumbnailUrl: thumbnailUrl
                })
            }
            
            // Update pagination state
            paginationCursor = cursor
            hasMorePages = cursor.length > 0
            
            isRefreshing = false
            isLoadingMore = false
            
            console.log("Streams model now has", streamsModel.count, "items")
            console.log("Has more pages:", hasMorePages)
        }
        
        onError: {
            console.error("Helix API error:", message)
            isRefreshing = false
            isLoadingMore = false
        }
    }
}
