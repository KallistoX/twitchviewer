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
        
        // Fetch user info if GraphQL token exists
        if (typeof twitchFetcher !== 'undefined' && twitchFetcher.hasGraphQLToken) {
            console.log("GraphQL token found, fetching user info...")
            twitchFetcher.fetchCurrentUser()
        }
        
        // Decide which page to show
        if (authManager.isAuthenticated && twitchFetcher.hasUserInfo) {
            console.log("User authenticated, loading FollowedPage")
            stackView.push(followedPage)
        } else {
            console.log("User not authenticated, loading CategoriesPage")
            stackView.push(categoriesPage)
        }
        
        // Show drawer in landscape mode by default
        if (width > height && width > units.gu(100)) {
            drawer.open()
        }
    }

    // ========================================
    // DRAWER (Sidebar Navigation)
    // ========================================
    
    Drawer {
        id: drawer
        width: units.gu(30)
        height: root.height
        edge: Qt.LeftEdge
        
        // Auto-open in landscape mode
        Connections {
            target: root
            onWidthChanged: {
                if (root.width > root.height && root.width > units.gu(100)) {
                    drawer.open()
                } else if (root.width <= units.gu(70)) {
                    drawer.close()
                }
            }
        }
        
        Rectangle {
            anchors.fill: parent
            color: theme.palette.normal.background
            
            Flickable {
                anchors.fill: parent
                contentHeight: drawerContent.height
                clip: true
                
                Column {
                    id: drawerContent
                    width: parent.width
                    spacing: 0
                    
                    // ========================================
                    // USER INFO HEADER (if logged in)
                    // ========================================
                    
                    Rectangle {
                        width: parent.width
                        height: userInfoContent.height + units.gu(2)
                        color: theme.palette.normal.base
                        visible: authManager.isAuthenticated && twitchFetcher.hasUserInfo
                        
                        Column {
                            id: userInfoContent
                            anchors {
                                margins: units.gu(2)
                                top: parent.top
                                left: parent.left
                                right: parent.right
                            }
                            spacing: units.gu(1)
                            
                            // Profile image
                            Rectangle {
                                width: units.gu(8)
                                height: units.gu(8)
                                radius: width / 2
                                color: theme.palette.normal.foreground
                                anchors.horizontalCenter: parent.horizontalCenter
                                clip: true
                                
                                Image {
                                    anchors.fill: parent
                                    source: twitchFetcher.currentUserProfileImage
                                    fillMode: Image.PreserveAspectCrop
                                    visible: source != ""
                                    smooth: true
                                }
                                
                                Icon {
                                    anchors.centerIn: parent
                                    name: "contact"
                                    width: units.gu(5)
                                    height: units.gu(5)
                                    visible: twitchFetcher.currentUserProfileImage == ""
                                }
                            }
                            
                            // Display name
                            Label {
                                text: twitchFetcher.currentUserDisplayName
                                font.bold: true
                                fontSize: "medium"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            // Login name
                            Label {
                                text: "@" + twitchFetcher.currentUserLogin
                                fontSize: "small"
                                color: theme.palette.normal.backgroundSecondaryText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            // Status badges
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: units.gu(0.5)
                                
                                Rectangle {
                                    width: adFreeLabel.width + units.gu(1)
                                    height: adFreeLabel.height + units.gu(0.5)
                                    radius: units.gu(0.5)
                                    color: twitchFetcher.hasGraphQLToken ? theme.palette.normal.positive : theme.palette.normal.base
                                    
                                    Label {
                                        id: adFreeLabel
                                        anchors.centerIn: parent
                                        text: "Ad-Free"
                                        fontSize: "x-small"
                                        color: twitchFetcher.hasGraphQLToken ? "white" : theme.palette.normal.backgroundSecondaryText
                                    }
                                }
                                
                                Rectangle {
                                    width: oauthLabel.width + units.gu(1)
                                    height: oauthLabel.height + units.gu(0.5)
                                    radius: units.gu(0.5)
                                    color: authManager.isAuthenticated ? theme.palette.normal.positive : theme.palette.normal.base
                                    
                                    Label {
                                        id: oauthLabel
                                        anchors.centerIn: parent
                                        text: "OAuth"
                                        fontSize: "x-small"
                                        color: authManager.isAuthenticated ? "white" : theme.palette.normal.backgroundSecondaryText
                                    }
                                }
                            }
                        }
                    }
                    
                    // ========================================
                    // LOGIN PROMPT (if not logged in)
                    // ========================================
                    
                    Rectangle {
                        width: parent.width
                        height: loginPrompt.height + units.gu(4)
                        color: theme.palette.normal.base
                        visible: !authManager.isAuthenticated
                        
                        Column {
                            id: loginPrompt
                            anchors {
                                margins: units.gu(2)
                                top: parent.top
                                left: parent.left
                                right: parent.right
                            }
                            spacing: units.gu(1)
                            
                            Icon {
                                name: "contact"
                                width: units.gu(6)
                                height: units.gu(6)
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Label {
                                text: i18n.tr("Not logged in")
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Button {
                                text: i18n.tr("Login to access followed streams")
                                width: parent.width
                                color: theme.palette.normal.positive
                                onClicked: {
                                    drawer.close()
                                    stackView.push(settingsPage)
                                }
                            }
                        }
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: units.dp(1)
                        color: theme.palette.normal.base
                    }
                    
                    // ========================================
                    // NAVIGATION ITEMS
                    // ========================================
                    
                    // Followed Channels (only if authenticated)
                    ListItem {
                        visible: authManager.isAuthenticated
                        height: units.gu(6)
                        
                        ListItemLayout {
                            title.text: i18n.tr("Followed Channels")
                            
                            Icon {
                                name: "stock_video"
                                width: units.gu(3)
                                height: units.gu(3)
                                SlotsLayout.position: SlotsLayout.Leading
                            }
                        }
                        
                        onClicked: {
                            console.log("Navigating to FollowedPage")
                            stackView.clear()
                            stackView.push(followedPage)
                            if (root.width <= units.gu(70)) {
                                drawer.close()
                            }
                        }
                    }
                    
                    // Browse Categories
                    ListItem {
                        height: units.gu(6)
                        
                        ListItemLayout {
                            title.text: i18n.tr("Browse Categories")
                            
                            Icon {
                                name: "view-grid-symbolic"
                                width: units.gu(3)
                                height: units.gu(3)
                                SlotsLayout.position: SlotsLayout.Leading
                            }
                        }
                        
                        onClicked: {
                            console.log("Navigating to CategoriesPage")
                            stackView.clear()
                            stackView.push(categoriesPage)
                            if (root.width <= units.gu(70)) {
                                drawer.close()
                            }
                        }
                    }
                    
                    // Settings
                    ListItem {
                        height: units.gu(6)
                        
                        ListItemLayout {
                            title.text: i18n.tr("Settings")
                            
                            Icon {
                                name: "settings"
                                width: units.gu(3)
                                height: units.gu(3)
                                SlotsLayout.position: SlotsLayout.Leading
                            }
                        }
                        
                        onClicked: {
                            console.log("Navigating to SettingsPage")
                            stackView.clear()
                            stackView.push(settingsPage)
                            if (root.width <= units.gu(70)) {
                                drawer.close()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // ========================================
    // MAIN CONTENT AREA (StackView)
    // ========================================
    
    StackView {
        id: stackView
        anchors.fill: parent
        
        // No initial item - we push it in onCompleted based on auth state
    }
    
    // ========================================
    // PAGE COMPONENTS
    // ========================================
    
    Component {
        id: followedPage
        FollowedPage {}
    }
    
    Component {
        id: categoriesPage
        CategoriesPage {}
    }
    
    Component {
        id: settingsPage
        SettingsPage {}
    }
    
    Component {
        id: playerPage
        PlayerPage {}
    }
    
    // ========================================
    // GLOBAL CONNECTIONS
    // ========================================
    
    Connections {
        target: authManager
        ignoreUnknownSignals: true
        
        onAuthenticationChanged: {
            console.log("Authentication changed:", authenticated)
            
            if (authenticated && twitchFetcher.hasUserInfo) {
                // User logged in, switch to FollowedPage
                stackView.clear()
                stackView.push(followedPage)
            } else if (!authenticated) {
                // User logged out, switch to CategoriesPage
                stackView.clear()
                stackView.push(categoriesPage)
            }
        }
    }
    
    Connections {
        target: twitchFetcher
        ignoreUnknownSignals: true
        
        onCurrentUserChanged: {
            console.log("User info changed")
            
            // If we just got user info and we're authenticated, switch to FollowedPage
            if (twitchFetcher.hasUserInfo && authManager.isAuthenticated) {
                if (stackView.currentItem !== followedPage) {
                    stackView.clear()
                    stackView.push(followedPage)
                }
            }
        }
    }
}
