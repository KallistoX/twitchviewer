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

Page {
    id: settingsPage

    // Force the page to match StackView width
    width: StackView.view ? StackView.view.width : parent.width
    height: StackView.view ? StackView.view.height : parent.height

    onWidthChanged: {
        console.log("SettingsPage width changed:", width)
    }

    Component.onCompleted: {
        console.log("SettingsPage created | width:", width)
    }

    header: PageHeader {
        id: settingsHeader
        title: i18n.tr('Settings')
        
        leadingActionBar.actions: [
            Action {
                iconName: "navigation-menu"
                text: i18n.tr("Menu")
                onTriggered: root.toggleSidebar()
            }
        ]
    }
    
    Flickable {
        id: settingsFlickable
        anchors {
            top: settingsHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        contentHeight: settingsColumn.height
        clip: true

        onWidthChanged: {
            console.log("SettingsPage Flickable width changed:", width, "| parent.width:", parent.width)
        }

        Column {
            id: settingsColumn
            spacing: units.gu(3)
            anchors {
                margins: units.gu(2)
                top: parent.top
                left: parent.left
                right: parent.right
            }

            onWidthChanged: {
                console.log("SettingsPage Column width changed:", width, "| parent.width:", parent.width)
            }
            
            // ========================================
            // SECTION 1: AD-FREE STREAMS (GraphQL Token)
            // ========================================
            
            Label {
                text: i18n.tr("Ad-Free Streams")
                font.bold: true
                fontSize: "large"
            }
            
            Rectangle {
                width: parent.width
                height: adFreeContent.height + units.gu(2)
                color: theme.palette.normal.background
                border.color: theme.palette.normal.base
                border.width: units.dp(1)
                radius: units.gu(1)
                
                Column {
                    id: adFreeContent
                    anchors {
                        margins: units.gu(1)
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    spacing: units.gu(1)
                    
                    Label {
                        width: parent.width
                        text: i18n.tr("Use your Twitch browser auth-token to watch streams without ads (Turbo/Subscriber only)")
                        wrapMode: Text.WordWrap
                        fontSize: "small"
                    }
                    
                    Label {
                        width: parent.width
                        text: i18n.tr("How to get your token:")
                        font.bold: true
                        fontSize: "small"
                    }
                    
                    Label {
                        width: parent.width
                        text: "1. Open twitch.tv in browser and login\n2. Open Developer Tools (F12)\n3. Go to Network tab\n4. Refresh page\n5. Find any gql.twitch.tv request\n6. Copy 'Authorization' header value (OAuth XXX...)\n7. Paste only the XXX... part below"
                        wrapMode: Text.WordWrap
                        fontSize: "x-small"
                        color: theme.palette.normal.backgroundSecondaryText
                    }
                    
                    // Token Input with Show/Hide button in Row
                    Row {
                        width: parent.width
                        spacing: units.gu(1)
                        
                        TextField {
                            id: gqlTokenInput
                            width: parent.width - showHideButton.width - units.gu(1)
                            placeholderText: i18n.tr('Paste auth-token here (30+ characters)')
                            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                            echoMode: TextInput.Password
                            
                            // Initialize with saved token
                            Component.onCompleted: {
                                text = twitchFetcher.getGraphQLToken()
                                            }
                            
                            // React to token changes from C++
                            Connections {
                                target: twitchFetcher
                                ignoreUnknownSignals: true
                                onGraphQLTokenChanged: {
                                    var savedToken = twitchFetcher.getGraphQLToken()
                                    if (gqlTokenInput.text !== savedToken) {
                                        gqlTokenInput.text = savedToken
                                                                }
                                }
                            }
                        }
                        
                        Button {
                            id: showHideButton
                            text: gqlTokenInput.echoMode === TextInput.Password ? "Show" : "Hide"
                            width: units.gu(10)
                            onClicked: {
                                gqlTokenInput.echoMode = (gqlTokenInput.echoMode === TextInput.Password) 
                                    ? TextInput.Normal 
                                    : TextInput.Password
                            }
                        }
                    }
                    
                    // Buttons
                    Row {
                        width: parent.width
                        spacing: units.gu(1)
                        
                        Button {
                            text: i18n.tr('Save Token')
                            color: theme.palette.normal.positive
                            enabled: gqlTokenInput.text.length > 20
                            width: (parent.width - units.gu(2)) / 3
                            onClicked: {
                                twitchFetcher.setGraphQLToken(gqlTokenInput.text)
                                gqlStatusLabel.text = "✅ Token saved!"
                                gqlStatusLabel.color = theme.palette.normal.positive
                            }
                        }
                        
                        Button {
                            text: i18n.tr('Validate')
                            enabled: twitchFetcher.hasGraphQLToken && !twitchFetcher.isValidatingToken
                            width: (parent.width - units.gu(2)) / 3
                            onClicked: {
                                gqlStatusLabel.text = "Testing token..."
                                gqlStatusLabel.color = theme.palette.normal.backgroundSecondaryText
                                twitchFetcher.validateGraphQLToken()
                            }
                            
                            ActivityIndicator {
                                anchors.centerIn: parent
                                running: twitchFetcher.isValidatingToken
                                visible: running
                            }
                        }
                        
                        Button {
                            text: i18n.tr('Clear')
                            color: theme.palette.normal.negative
                            enabled: twitchFetcher.hasGraphQLToken
                            width: (parent.width - units.gu(2)) / 3
                            onClicked: {
                                twitchFetcher.clearGraphQLToken()
                                gqlTokenInput.text = ""
                                gqlStatusLabel.text = "Token cleared"
                                gqlStatusLabel.color = theme.palette.normal.backgroundSecondaryText
                            }
                        }
                    }
                    
                    // Status Label
                    Label {
                        id: gqlStatusLabel
                        width: parent.width
                        text: twitchFetcher.hasGraphQLToken ? "✅ Token configured" : "No token configured"
                        wrapMode: Text.WordWrap
                        fontSize: "small"
                        visible: text.length > 0
                    }
                    
                    
                    Label {
                        width: parent.width
                        text: i18n.tr("Note: Token remains valid for months unless you logout or change password on Twitch.")
                        wrapMode: Text.WordWrap
                        fontSize: "x-small"
                        color: theme.palette.normal.backgroundSecondaryText
                    }
                }
            }
            
            // ========================================
            // SECTION 2: TWITCH ACCOUNT (OAuth)
            // ========================================
            
            Label {
                text: i18n.tr("Twitch Account")
                font.bold: true
                fontSize: "large"
            }
            
            Rectangle {
                width: parent.width
                height: oauthContent.height + units.gu(2)
                color: theme.palette.normal.background
                border.color: theme.palette.normal.base
                border.width: units.dp(1)
                radius: units.gu(1)
                
                Column {
                    id: oauthContent
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
                            text: i18n.tr("Login to access followed streams and account features")
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
                            text: i18n.tr("You can now access followed streams and account features")
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
                        id: oauthStatusLabel
                        width: parent.width
                        text: ""
                        wrapMode: Text.WordWrap
                        fontSize: "small"
                        visible: text.length > 0
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
    
    // Connections to fetcher for validation results
    Connections {
        target: twitchFetcher
        ignoreUnknownSignals: true
        
        onTokenValidationSuccess: {
            gqlStatusLabel.text = message
            gqlStatusLabel.color = theme.palette.normal.positive
        }
        
        onTokenValidationFailed: {
            gqlStatusLabel.text = "❌ " + message
            gqlStatusLabel.color = theme.palette.normal.negative
        }
    }
    
    // Connections to auth manager
    Connections {
        target: authManager
        ignoreUnknownSignals: true
        
        onAuthenticationSucceeded: {
            oauthStatusLabel.text = i18n.tr("✅ Successfully logged in!")
            oauthStatusLabel.color = theme.palette.normal.positive
        }
        
        onAuthenticationFailed: {
            oauthStatusLabel.text = i18n.tr("❌ Error: ") + message
            oauthStatusLabel.color = theme.palette.normal.negative
        }
        
        onStatusMessage: {
            oauthStatusLabel.text = message
            oauthStatusLabel.color = theme.palette.normal.backgroundSecondaryText
        }
    }
}
