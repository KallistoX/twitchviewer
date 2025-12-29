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
    id: categoriesPage
    
    property bool isRefreshing: false
    
    header: PageHeader {
        id: pageHeader
        title: i18n.tr('Browse')
        
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
                onTriggered: refreshCategories()
            }
        ]
    }
    
    // Categories model
    ListModel {
        id: categoryModel
    }
    
    Flickable {
        anchors {
            top: pageHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        contentHeight: contentColumn.height
        clip: true
        
        Column {
            id: contentColumn
            width: parent.width
            spacing: units.gu(2)
            padding: units.gu(2)
            
            // ========================================
            // MANUAL CHANNEL INPUT
            // ========================================
            
            Label {
                text: i18n.tr('Watch a Channel')
                font.bold: true
                fontSize: "large"
                width: parent.width - units.gu(4)
            }
            
            Row {
                width: parent.width - units.gu(4)
                spacing: units.gu(1)
                
                TextField {
                    id: channelInput
                    width: parent.width - watchButton.width - units.gu(1)
                    placeholderText: i18n.tr('Enter channel name (e.g. nasa)')
                    inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhUrlCharactersOnly
                    
                    onAccepted: {
                        if (text.length > 0) {
                            watchStream(text)
                        }
                    }
                }
                
                Button {
                    id: watchButton
                    text: i18n.tr('Watch')
                    color: theme.palette.normal.positive
                    enabled: channelInput.text.length > 0
                    onClicked: watchStream(channelInput.text)
                }
            }
            
            // ========================================
            // TOP CATEGORIES
            // ========================================
            
            Label {
                text: i18n.tr('Top Categories')
                font.bold: true
                fontSize: "large"
                width: parent.width - units.gu(4)
            }
            
            // Loading indicator
            ActivityIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: isRefreshing
                visible: running
            }
            
            // Empty state
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: categoryModel.count === 0 && !isRefreshing ? i18n.tr('No categories available') : ""
                visible: text.length > 0
                color: theme.palette.normal.backgroundSecondaryText
            }
            
            // Categories grid
            GridView {
                id: categoryGrid
                width: parent.width - units.gu(4)
                height: {
                    if (count === 0) return 0
                    var rows = Math.ceil(count / columnsCount)
                    return rows * cellHeight
                }
                
                clip: true
                interactive: false  // Let Flickable handle scrolling
                model: categoryModel
                
                // Responsive columns
                property int columnsCount: {
                    if (width > units.gu(100)) return 5      // Wide landscape (tablet)
                    else if (width > units.gu(70)) return 4  // Landscape
                    else return 3                             // Portrait
                }
                
                cellWidth: width / columnsCount
                cellHeight: units.gu(30)
                
                delegate: Item {
                    width: categoryGrid.cellWidth
                    height: categoryGrid.cellHeight
                    
                    Rectangle {
                        anchors {
                            fill: parent
                            margins: units.gu(0.5)
                        }
                        color: "transparent"
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: units.gu(1)
                            width: parent.width
                            
                            // Box art
                            Rectangle {
                                width: Math.min(parent.width - units.gu(2), units.gu(12))
                                height: width * 4 / 3
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: theme.palette.normal.base
                                radius: units.gu(1)
                                clip: true
                                
                                Image {
                                    anchors.fill: parent
                                    source: model.boxArtUrl
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }
                                
                                // Viewer count badge (if available)
                                Rectangle {
                                    anchors {
                                        right: parent.right
                                        bottom: parent.bottom
                                        margins: units.gu(0.5)
                                    }
                                    width: viewerCountLabel.width + units.gu(1)
                                    height: viewerCountLabel.height + units.gu(0.5)
                                    color: Qt.rgba(0, 0, 0, 0.7)
                                    radius: units.gu(0.5)
                                    visible: model.viewersCount > 0
                                    
                                    Label {
                                        id: viewerCountLabel
                                        anchors.centerIn: parent
                                        text: {
                                            var count = model.viewersCount
                                            if (count >= 1000000) {
                                                return (count / 1000000).toFixed(1) + "M"
                                            } else if (count >= 1000) {
                                                return (count / 1000).toFixed(1) + "K"
                                            } else {
                                                return count.toString()
                                            }
                                        }
                                        color: "white"
                                        fontSize: "x-small"
                                    }
                                }
                            }
                            
                            // Category name
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
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log("Category clicked:", model.name, "id:", model.id)
                                // TODO: Navigate to streams for this category
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Functions
    function refreshCategories() {
        console.log("Refreshing categories...")
        isRefreshing = true
        
        if (authManager.isAuthenticated) {
            // Use Helix API (logged in, better performance)
            console.log("Using Helix API (authenticated)")
            helixApi.getTopGames(20)
        } else {
            // Use GraphQL (anonymous, no auth required)
            console.log("Using GraphQL (anonymous)")
            twitchFetcher.fetchTopCategoriesGraphQL(30)
        }
    }
    
    function watchStream(channelName) {
        console.log("Starting stream:", channelName)
        stackView.push(playerPage, {
            channelName: channelName,
            requestedQuality: "best"
        })
    }
    
    // Load categories on component completion
    Component.onCompleted: {
        console.log("CategoriesPage loaded")
        refreshCategories()
    }
    
    // Connections - Helix API (authenticated)
    Connections {
        target: helixApi
        ignoreUnknownSignals: true
        
        onTopGamesReceived: {
            console.log("Top games received from Helix API:", games.length)
            categoryModel.clear()
            
            for (var i = 0; i < games.length; i++) {
                var game = games[i]
                var boxArtUrl = game.box_art_url
                boxArtUrl = boxArtUrl.replace("{width}", "285")
                boxArtUrl = boxArtUrl.replace("{height}", "380")
                
                categoryModel.append({
                    id: game.id,
                    name: game.name,
                    boxArtUrl: boxArtUrl,
                    viewersCount: 0  // Helix doesn't provide viewer count
                })
            }
            
            isRefreshing = false
            console.log("Category model populated with", categoryModel.count, "items (Helix)")
        }
    }
    
    // Connections - GraphQL (anonymous)
    Connections {
        target: twitchFetcher
        ignoreUnknownSignals: true
        
        onTopCategoriesReceived: {
            console.log("Top categories received from GraphQL:", categories.length)
            categoryModel.clear()
            
            for (var i = 0; i < categories.length; i++) {
                var cat = categories[i]
                
                categoryModel.append({
                    id: cat.id,
                    name: cat.name,
                    boxArtUrl: cat.boxArtUrl,
                    viewersCount: cat.viewersCount || 0
                })
            }
            
            isRefreshing = false
            console.log("Category model populated with", categoryModel.count, "items (GraphQL)")
        }
    }
    
    // Error handling
    Connections {
        target: helixApi
        ignoreUnknownSignals: true
        
        onError: {
            console.error("Helix API error:", message)
            isRefreshing = false
        }
    }
    
    Connections {
        target: twitchFetcher
        ignoreUnknownSignals: true
        
        onError: {
            console.error("GraphQL error:", message)
            isRefreshing = false
        }
    }
}
