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
    id: settingsPage
    
    header: PageHeader {
        id: settingsHeader
        title: i18n.tr('Settings')
        
        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: i18n.tr("Back")
                onTriggered: pageStack.pop()
            }
        ]
    }
    
    Flickable {
        anchors {
            top: settingsHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        contentHeight: settingsColumn.height
        clip: true
        
        Column {
            id: settingsColumn
            spacing: units.gu(2)
            anchors {
                margins: units.gu(2)
                top: parent.top
                left: parent.left
                right: parent.right
            }
            width: parent.width - units.gu(4)
            
            // ========================================
            // TWITCH LOGIN SECTION
            // ========================================
            
            Label {
                text: i18n.tr("Twitch Account")
                font.bold: true
                fontSize: "large"
            }
            
            Rectangle {
                width: parent.width
                height: loginContent.height + units.gu(2)
                color: theme.palette.normal.background
                border.color: theme.palette.normal.base
                border.width: units.dp(1)
                radius: units.gu(1)
                
                Column {
                    id: loginContent
                    anchors {
                        margins: units.gu(1)
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    spacing: units.gu(1)
                    
                    // NOT LOGGED IN STATE
                    Column {
                        visible: !authManager.isAuthenticated
                        width: parent.width
                        spacing: units.gu(1)
                        
                        Label {
                            width: parent.width
                            text: i18n.tr("Login to watch streams without ads (Turbo/Sub users)")
                            wrapMode: Text.WordWrap
                            fontSize: "small"
                        }
                        
                        Button {
                            text: i18n.tr("Login with Twitch")
                            color: "#9146FF" // Twitch purple
                            width: parent.width
                            onClicked: {
                                authManager.startDeviceAuth()
                            }
                        }
                    }
                    
                    // DEVICE CODE DISPLAY (during authorization)
                    Column {
                        visible: authManager.isPolling
                        width: parent.width
                        spacing: units.gu(1)
                        
                        Label {
                            width: parent.width
                            text: i18n.tr("1. Visit this URL on any device:")
                            wrapMode: Text.WordWrap
                            font.bold: true
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: urlLabel.height + units.gu(1)
                            color: theme.palette.normal.base
                            radius: units.gu(0.5)
                            
                            Label {
                                id: urlLabel
                                anchors.centerIn: parent
                                text: authManager.verificationUrl
                                color: "#9146FF"
                                font.pixelSize: units.gu(2)
                            }
                        }
                        
                        Label {
                            width: parent.width
                            text: i18n.tr("2. Enter this code:")
                            wrapMode: Text.WordWrap
                            font.bold: true
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: codeLabel.height + units.gu(2)
                            color: "#9146FF"
                            radius: units.gu(0.5)
                            
                            Label {
                                id: codeLabel
                                anchors.centerIn: parent
                                text: authManager.userCode
                                color: "white"
                                font.pixelSize: units.gu(5)
                                font.bold: true
                                font.family: "monospace"
                            }
                        }
                        
                        Button {
                            text: i18n.tr("Copy Code")
                            width: parent.width
                            onClicked: {
                                // Copy to clipboard (requires Lomiri.Content or Qt.labs.platform)
                                // For now just show message
                                statusLabel.text = "Code: " + authManager.userCode
                            }
                        }
                        
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: units.gu(1)
                            
                            ActivityIndicator {
                                running: true
                            }
                            
                            Label {
                                text: i18n.tr("Waiting for authorization...")
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        
                        Button {
                            text: i18n.tr("Cancel")
                            width: parent.width
                            color: theme.palette.normal.negative
                            onClicked: {
                                authManager.logout()
                            }
                        }
                    }
                    
                    // LOGGED IN STATE
                    Column {
                        visible: authManager.isAuthenticated && !authManager.isPolling
                        width: parent.width
                        spacing: units.gu(1)
                        
                        Row {
                            width: parent.width
                            spacing: units.gu(1)
                            
                            Icon {
                                name: "tick"
                                width: units.gu(3)
                                height: units.gu(3)
                                color: theme.palette.normal.positive
                            }
                            
                            Label {
                                text: i18n.tr("Logged in to Twitch")
                                color: theme.palette.normal.positive
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        
                        Label {
                            width: parent.width
                            text: i18n.tr("You can now watch streams without ads (if you have Turbo or are subscribed to the channel)")
                            wrapMode: Text.WordWrap
                            fontSize: "small"
                        }
                        
                        Button {
                            text: i18n.tr("Logout")
                            width: parent.width
                            color: theme.palette.normal.negative
                            onClicked: {
                                authManager.logout()
                            }
                        }
                    }
                    
                    // Status Label
                    Label {
                        id: statusLabel
                        width: parent.width
                        text: ""
                        wrapMode: Text.WordWrap
                        fontSize: "small"
                        visible: text.length > 0
                    }
                }
            }
            
            // ========================================
            // DEBUG INFO SECTION
            // ========================================
            
            Label {
                text: i18n.tr("Debug Information")
                font.bold: true
                fontSize: "large"
            }
            
            Rectangle {
                width: parent.width
                height: debugContent.height + units.gu(2)
                color: theme.palette.normal.background
                border.color: theme.palette.normal.base
                border.width: units.dp(1)
                radius: units.gu(1)
                
                Column {
                    id: debugContent
                    anchors {
                        margins: units.gu(1)
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    spacing: units.gu(0.5)
                    
                    // Authentication Status
                    Row {
                        width: parent.width
                        spacing: units.gu(1)
                        
                        Label {
                            text: i18n.tr("Authenticated:")
                            width: units.gu(15)
                            font.bold: true
                        }
                        
                        Label {
                            text: authManager.isAuthenticated ? "Yes ✅" : "No ❌"
                            color: authManager.isAuthenticated ? theme.palette.normal.positive : theme.palette.normal.negative
                        }
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: units.dp(1)
                        color: theme.palette.normal.base
                    }
                    
                    // Stream Info (from last fetch)
                    Label {
                        text: i18n.tr("Last Stream Info:")
                        font.bold: true
                        fontSize: "small"
                    }
                    
                    Row {
                        width: parent.width
                        spacing: units.gu(1)
                        
                        Label {
                            text: "Show Ads:"
                            width: units.gu(15)
                            fontSize: "small"
                        }
                        
                        Label {
                            text: twitchFetcher.debugShowAds
                            color: twitchFetcher.debugShowAds === "true" ? theme.palette.normal.negative : theme.palette.normal.positive
                            fontSize: "small"
                        }
                    }
                    
                    Row {
                        width: parent.width
                        spacing: units.gu(1)
                        
                        Label {
                            text: "Hide Ads:"
                            width: units.gu(15)
                            fontSize: "small"
                        }
                        
                        Label {
                            text: twitchFetcher.debugHideAds
                            color: twitchFetcher.debugHideAds === "true" ? theme.palette.normal.positive : theme.palette.normal.negative
                            fontSize: "small"
                        }
                    }
                    
                    Row {
                        width: parent.width
                        spacing: units.gu(1)
                        
                        Label {
                            text: "Privileged:"
                            width: units.gu(15)
                            fontSize: "small"
                        }
                        
                        Label {
                            text: twitchFetcher.debugPrivileged
                            fontSize: "small"
                        }
                    }
                    
                    Row {
                        width: parent.width
                        spacing: units.gu(1)
                        
                        Label {
                            text: "Role:"
                            width: units.gu(15)
                            fontSize: "small"
                        }
                        
                        Label {
                            text: twitchFetcher.debugRole.length > 0 ? twitchFetcher.debugRole : "(none)"
                            fontSize: "small"
                        }
                    }
                    
                    Row {
                        width: parent.width
                        spacing: units.gu(1)
                        
                        Label {
                            text: "Subscriber:"
                            width: units.gu(15)
                            fontSize: "small"
                        }
                        
                        Label {
                            text: twitchFetcher.debugSubscriber
                            fontSize: "small"
                        }
                    }
                    
                    Row {
                        width: parent.width
                        spacing: units.gu(1)
                        
                        Label {
                            text: "Turbo:"
                            width: units.gu(15)
                            fontSize: "small"
                        }
                        
                        Label {
                            text: twitchFetcher.debugTurbo
                            fontSize: "small"
                        }
                    }
                    
                    Row {
                        width: parent.width
                        spacing: units.gu(1)
                        
                        Label {
                            text: "Adblock:"
                            width: units.gu(15)
                            fontSize: "small"
                        }
                        
                        Label {
                            text: twitchFetcher.debugAdblock
                            fontSize: "small"
                        }
                    }
                    
                    Label {
                        width: parent.width
                        text: i18n.tr("These values are from the last stream you opened. They show whether Twitch is serving you ads.")
                        wrapMode: Text.WordWrap
                        fontSize: "x-small"
                        color: theme.palette.normal.backgroundSecondaryText
                    }
                }
            }
            
            // ========================================
            // ABOUT SECTION
            // ========================================
            
            Label {
                text: i18n.tr("About")
                font.bold: true
                fontSize: "large"
            }
            
            Rectangle {
                width: parent.width
                height: aboutContent.height + units.gu(2)
                color: theme.palette.normal.background
                border.color: theme.palette.normal.base
                border.width: units.dp(1)
                radius: units.gu(1)
                
                Column {
                    id: aboutContent
                    anchors {
                        margins: units.gu(1)
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    spacing: units.gu(1)
                    
                    Label {
                        width: parent.width
                        text: "TwitchViewer for Ubuntu Touch"
                        font.bold: true
                    }
                    
                    Label {
                        width: parent.width
                        text: "Version 1.0.0"
                        fontSize: "small"
                    }
                    
                    Label {
                        width: parent.width
                        text: i18n.tr("A native Twitch client for Ubuntu Touch")
                        wrapMode: Text.WordWrap
                        fontSize: "small"
                    }
                    
                    Label {
                        width: parent.width
                        text: "© 2025 Dominic Bussemas"
                        fontSize: "small"
                    }
                    
                    Label {
                        width: parent.width
                        text: i18n.tr("Licensed under GNU GPLv3")
                        fontSize: "small"
                    }
                }
            }
        }
    }
    
    // Connections to auth manager
    Connections {
        target: authManager
        ignoreUnknownSignals: true
        
        onAuthenticationSucceeded: {
            statusLabel.text = i18n.tr("✅ Successfully logged in!")
            statusLabel.color = theme.palette.normal.positive
        }
        
        onAuthenticationFailed: {
            statusLabel.text = i18n.tr("❌ Error: ") + message
            statusLabel.color = theme.palette.normal.negative
        }
        
        onStatusMessage: {
            statusLabel.text = message
            statusLabel.color = theme.palette.normal.backgroundSecondaryText
        }
    }
}
