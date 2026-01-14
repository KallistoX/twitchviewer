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
import QtGraphicalEffects 1.15

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'twitchviewer.kallisto-app'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)
    
    // Background color from theme
    backgroundColor: ThemeManager.backgroundColor

    Component.onCompleted: {
        // Fetch user info if GraphQL token exists
        if (typeof twitchFetcher !== 'undefined' && twitchFetcher.hasGraphQLToken) {
            twitchFetcher.fetchCurrentUser()
        }

        // Decide which page to show
        if (authManager.isAuthenticated && twitchFetcher.hasUserInfo) {
            stackView.push(followedPage)
        } else {
            stackView.push(categoriesPage)
        }

        // Open sidebar/drawer in wide mode by default
        if (!useOverlayMode && !player.isActive) {
            sidebarOpen = true
        } else if (useOverlayMode && width > units.gu(100)) {
            drawer.open()
        }
    }

    // Function to toggle sidebar/drawer (can be called from hamburger button)
    function toggleSidebar() {
        if (useOverlayMode) {
            if (drawer.position > 0) {
                drawer.close()
            } else {
                drawer.open()
            }
        } else {
            sidebarOpen = !sidebarOpen
        }
    }

    // ========================================
    // OFFLINE BANNER
    // ========================================
    
    Rectangle {
        id: offlineBanner
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: units.gu(5)
        color: "#FF6B00"  // Orange warning color
        z: 1000  // Always on top
        visible: (typeof networkManager !== 'undefined') && (networkManager.hasActiveError || !networkManager.isOnline)
        
        Row {
            anchors.centerIn: parent
            spacing: units.gu(1)
            
            Icon {
                name: "network-offline"
                width: units.gu(3)
                height: units.gu(3)
                color: "white"
            }
            
            Label {
                text: i18n.tr("No internet connection - Using offline mode")
                color: "white"
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        
        Behavior on height {
            NumberAnimation { duration: 200 }
        }
    }
    
    // ========================================
    // NETWORK MANAGER CONNECTIONS
    // ========================================
    
    Connections {
        target: networkManager
        ignoreUnknownSignals: true

        onOnlineStatusChanged: {
                }

        onActiveErrorChanged: {
                }

        onConnectionRestored: {

            // Retry failed operations

            // Fetch user info if we have GraphQL token but no user info yet
            if (typeof twitchFetcher !== 'undefined' && twitchFetcher.hasGraphQLToken && !twitchFetcher.hasUserInfo) {
                twitchFetcher.fetchCurrentUser()
            }

            // Refresh current page content
            if (stackView.currentItem) {
                // If on FollowedPage, refresh followed streams
                if (stackView.currentItem.objectName === "followedPage") {
                    if (authManager.isAuthenticated && twitchFetcher.hasUserInfo) {
                        helixApi.getFollowedStreams(twitchFetcher.currentUserId, 100)
                    }
                }
                // If on CategoriesPage, refresh categories
                else if (stackView.currentItem.objectName === "categoriesPage") {
                    if (typeof stackView.currentItem.refreshCategories === 'function') {
                        stackView.currentItem.refreshCategories()
                    }
                }
            }

            // Optional: Show success notification
            Qt.createQmlObject(
                'import QtQuick 2.15; import Lomiri.Components 1.3; ' +
                'Label { ' +
                '    text: "✅ Connection restored"; ' +
                '    color: "green"; ' +
                '    font.bold: true; ' +
                '    Timer { running: true; interval: 3000; onTriggered: parent.destroy() } ' +
                '}',
                root,
                "connectionRestoredLabel"
            )
        }
        
        onConnectionLost: {
        }
    }

    // ========================================
    // RESPONSIVE SIDEBAR/DRAWER
    // ========================================

    // Determine mode based on screen width
    property bool useOverlayMode: root.width <= units.gu(70)
    property bool sidebarOpen: false

    // Handle width changes
    Connections {
        target: root
        onWidthChanged: {
            if (!useOverlayMode && !player.isActive) {
                sidebarOpen = true
            } else if (useOverlayMode) {
                sidebarOpen = false
            }
        }
    }

    // Close sidebar when player goes fullscreen
    Connections {
        target: player
        onPlayerMaximized: {
            sidebarOpen = false
        }
    }

    // OVERLAY MODE: Traditional Drawer (Smartphone)
    Drawer {
        id: drawer
        visible: useOverlayMode
        y: offlineBanner.visible ? offlineBanner.height : 0
        width: units.gu(30)
        height: root.height
        edge: Qt.LeftEdge

        Rectangle {
            anchors.fill: parent
            color: ThemeManager.surfaceColor

            Flickable {
                anchors.fill: parent
                contentHeight: drawerContent.height
                clip: true

                Column {
                    id: drawerContent
                    width: parent.width
                    spacing: 0
                    
                    // ========================================
                    // DARK MODE TOGGLE
                    // ========================================
                    
                    Rectangle {
                        width: parent.width
                        height: units.gu(6)
                        color: ThemeManager.cardColor
                        
                        Row {
                            anchors {
                                left: parent.left
                                right: parent.right
                                margins: units.gu(2)
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: units.gu(1)
                            
                            Icon {
                                name: ThemeManager.isDarkMode ? "torch-on" : "torch-off"
                                width: units.gu(3)
                                height: units.gu(3)
                                color: ThemeManager.textPrimary
                            }
                            
                            Label {
                                text: i18n.tr("Dark Mode")
                                color: ThemeManager.textPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Item { Layout.fillWidth: true; width: units.gu(1) }
                            
                            Switch {
                                id: darkModeSwitch
                                checked: ThemeManager.isDarkMode
                                anchors.verticalCenter: parent.verticalCenter
                                
                                onCheckedChanged: {
                                    if (checked !== ThemeManager.isDarkMode) {
                                        ThemeManager.toggleDarkMode()
                                    }
                                }
                            }
                        }
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: units.dp(1)
                        color: ThemeManager.dividerColor
                    }
                    
                    // ========================================
                    // USER INFO HEADER (if logged in)
                    // ========================================
                    
                    Rectangle {
                        width: parent.width
                        height: userInfoContent.height + units.gu(2)
                        color: ThemeManager.cardColor
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
                                color: ThemeManager.borderColor
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
                                    color: ThemeManager.textSecondary
                                }
                            }
                            
                            // Display name
                            Label {
                                text: twitchFetcher.currentUserDisplayName
                                font.bold: true
                                fontSize: "medium"
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: ThemeManager.textPrimary
                            }
                            
                            // Login name
                            Label {
                                text: "@" + twitchFetcher.currentUserLogin
                                fontSize: "small"
                                color: ThemeManager.textSecondary
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
                                    color: twitchFetcher.hasGraphQLToken ? ThemeManager.positiveColor : ThemeManager.cardColor
                                    
                                    Label {
                                        id: adFreeLabel
                                        anchors.centerIn: parent
                                        text: "Ad-Free"
                                        fontSize: "x-small"
                                        color: twitchFetcher.hasGraphQLToken ? "white" : ThemeManager.textSecondary
                                    }
                                }
                                
                                Rectangle {
                                    width: oauthLabel.width + units.gu(1)
                                    height: oauthLabel.height + units.gu(0.5)
                                    radius: units.gu(0.5)
                                    color: authManager.isAuthenticated ? ThemeManager.positiveColor : ThemeManager.cardColor
                                    
                                    Label {
                                        id: oauthLabel
                                        anchors.centerIn: parent
                                        text: "OAuth"
                                        fontSize: "x-small"
                                        color: authManager.isAuthenticated ? "white" : ThemeManager.textSecondary
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
                        color: ThemeManager.cardColor
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
                                color: ThemeManager.textSecondary
                            }
                            
                            Label {
                                text: i18n.tr("Not logged in")
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: ThemeManager.textPrimary
                            }
                            
                            Button {
                                text: i18n.tr("Login to access followed streams")
                                width: parent.width
                                color: ThemeManager.accentColor
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
                        color: ThemeManager.dividerColor
                    }
                    
                    // ========================================
                    // NAVIGATION ITEMS
                    // ========================================
                    
                    // Followed Channels (only if authenticated)
                    ListItem {
                        visible: authManager.isAuthenticated
                        height: units.gu(6)
                        color: ThemeManager.surfaceColor
                        
                        ListItemLayout {
                            title.text: i18n.tr("Followed Channels")
                            title.color: ThemeManager.textPrimary
                            
                            Icon {
                                name: "stock_video"
                                width: units.gu(3)
                                height: units.gu(3)
                                color: ThemeManager.textPrimary
                                SlotsLayout.position: SlotsLayout.Leading
                            }
                        }

                        onClicked: {
                            stackView.clear()
                            stackView.push(followedPage)
                            if (useOverlayMode) {
                                drawer.close()
                            }
                        }
                    }

                    // Browse Categories
                    ListItem {
                        height: units.gu(6)
                        color: ThemeManager.surfaceColor

                        ListItemLayout {
                            title.text: i18n.tr("Browse Categories")
                            title.color: ThemeManager.textPrimary

                            Icon {
                                name: "view-grid-symbolic"
                                width: units.gu(3)
                                height: units.gu(3)
                                color: ThemeManager.textPrimary
                                SlotsLayout.position: SlotsLayout.Leading
                            }
                        }

                        onClicked: {
                            stackView.clear()
                            stackView.push(categoriesPage)
                            if (useOverlayMode) {
                                drawer.close()
                            }
                        }
                    }

                    // Settings
                    ListItem {
                        height: units.gu(6)
                        color: ThemeManager.surfaceColor

                        ListItemLayout {
                            title.text: i18n.tr("Settings")
                            title.color: ThemeManager.textPrimary

                            Icon {
                                name: "settings"
                                width: units.gu(3)
                                height: units.gu(3)
                                color: ThemeManager.textPrimary
                                SlotsLayout.position: SlotsLayout.Leading
                            }
                        }

                        onClicked: {
                            stackView.clear()
                            stackView.push(settingsPage)
                            if (useOverlayMode) {
                                drawer.close()
                            }
                        }
                    }
                }
            }
        }
    }

    // RESIZE MODE: Sidebar with Row Layout (Tablet/Landscape)
    Rectangle {
        id: resizeSidebar
        visible: !useOverlayMode
        y: offlineBanner.visible ? offlineBanner.height : 0
        width: sidebarOpen ? units.gu(30) : 0
        height: root.height - y
        color: ThemeManager.surfaceColor
        clip: true

        Behavior on width {
            NumberAnimation { duration: UbuntuAnimation.FastDuration }
        }

        Flickable {
            anchors.fill: parent
            contentHeight: resizeSidebarContent.height
            visible: sidebarOpen

            Column {
                id: resizeSidebarContent
                width: parent.width
                spacing: 0

                // ========================================
                // DARK MODE TOGGLE
                // ========================================

                Rectangle {
                    width: parent.width
                    height: units.gu(6)
                    color: ThemeManager.cardColor

                    Row {
                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: units.gu(2)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: units.gu(1)

                        Icon {
                            name: ThemeManager.isDarkMode ? "torch-on" : "torch-off"
                            width: units.gu(3)
                            height: units.gu(3)
                            color: ThemeManager.textPrimary
                        }

                        Label {
                            text: i18n.tr("Dark Mode")
                            color: ThemeManager.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item { Layout.fillWidth: true; width: units.gu(1) }

                        Switch {
                            checked: ThemeManager.isDarkMode
                            anchors.verticalCenter: parent.verticalCenter

                            onCheckedChanged: {
                                if (checked !== ThemeManager.isDarkMode) {
                                    ThemeManager.toggleDarkMode()
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: units.dp(1)
                    color: ThemeManager.dividerColor
                }

                // ========================================
                // USER INFO HEADER (if logged in)
                // ========================================

                Rectangle {
                    width: parent.width
                    height: resizeUserInfoContent.height + units.gu(2)
                    color: ThemeManager.cardColor
                    visible: authManager.isAuthenticated && twitchFetcher.hasUserInfo

                    Column {
                        id: resizeUserInfoContent
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
                            color: ThemeManager.borderColor
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
                                color: ThemeManager.textSecondary
                            }
                        }

                        // Display name
                        Label {
                            text: twitchFetcher.currentUserDisplayName
                            font.bold: true
                            fontSize: "medium"
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: ThemeManager.textPrimary
                        }

                        // Login name
                        Label {
                            text: "@" + twitchFetcher.currentUserLogin
                            fontSize: "small"
                            color: ThemeManager.textSecondary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        // Status badges
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: units.gu(0.5)

                            Rectangle {
                                width: resizeAdFreeLabel.width + units.gu(1)
                                height: resizeAdFreeLabel.height + units.gu(0.5)
                                radius: units.gu(0.5)
                                color: twitchFetcher.hasGraphQLToken ? ThemeManager.positiveColor : ThemeManager.cardColor

                                Label {
                                    id: resizeAdFreeLabel
                                    anchors.centerIn: parent
                                    text: "Ad-Free"
                                    fontSize: "x-small"
                                    color: twitchFetcher.hasGraphQLToken ? "white" : ThemeManager.textSecondary
                                }
                            }

                            Rectangle {
                                width: resizeOauthLabel.width + units.gu(1)
                                height: resizeOauthLabel.height + units.gu(0.5)
                                radius: units.gu(0.5)
                                color: authManager.isAuthenticated ? ThemeManager.positiveColor : ThemeManager.cardColor

                                Label {
                                    id: resizeOauthLabel
                                    anchors.centerIn: parent
                                    text: "OAuth"
                                    fontSize: "x-small"
                                    color: authManager.isAuthenticated ? "white" : ThemeManager.textSecondary
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
                    height: resizeLoginPrompt.height + units.gu(4)
                    color: ThemeManager.cardColor
                    visible: !authManager.isAuthenticated

                    Column {
                        id: resizeLoginPrompt
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
                            color: ThemeManager.textSecondary
                        }

                        Label {
                            text: i18n.tr("Not logged in")
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: ThemeManager.textPrimary
                        }

                        Button {
                            text: i18n.tr("Login to access followed streams")
                            width: parent.width
                            color: ThemeManager.accentColor
                            onClicked: {
                                stackView.push(settingsPage)
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: units.dp(1)
                    color: ThemeManager.dividerColor
                }

                // ========================================
                // NAVIGATION ITEMS
                // ========================================

                // Followed Channels (only if authenticated)
                ListItem {
                    visible: authManager.isAuthenticated
                    height: units.gu(6)
                    color: ThemeManager.surfaceColor

                    ListItemLayout {
                        title.text: i18n.tr("Followed Channels")
                        title.color: ThemeManager.textPrimary

                        Icon {
                            name: "stock_video"
                            width: units.gu(3)
                            height: units.gu(3)
                            color: ThemeManager.textPrimary
                            SlotsLayout.position: SlotsLayout.Leading
                        }
                    }

                    onClicked: {
                        stackView.clear()
                        stackView.push(followedPage)
                    }
                }

                // Browse Categories
                ListItem {
                    height: units.gu(6)
                    color: ThemeManager.surfaceColor

                    ListItemLayout {
                        title.text: i18n.tr("Browse Categories")
                        title.color: ThemeManager.textPrimary

                        Icon {
                            name: "view-grid-symbolic"
                            width: units.gu(3)
                            height: units.gu(3)
                            color: ThemeManager.textPrimary
                            SlotsLayout.position: SlotsLayout.Leading
                        }
                    }

                    onClicked: {
                        stackView.clear()
                        stackView.push(categoriesPage)
                    }
                }

                // Settings
                ListItem {
                    height: units.gu(6)
                    color: ThemeManager.surfaceColor

                    ListItemLayout {
                        title.text: i18n.tr("Settings")
                        title.color: ThemeManager.textPrimary

                        Icon {
                            name: "settings"
                            width: units.gu(3)
                            height: units.gu(3)
                            color: ThemeManager.textPrimary
                            SlotsLayout.position: SlotsLayout.Leading
                        }
                    }

                    onClicked: {
                        stackView.clear()
                        stackView.push(settingsPage)
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
        x: useOverlayMode ? 0 : resizeSidebar.width
        y: offlineBanner.visible ? offlineBanner.height : 0
        width: parent.width - (useOverlayMode ? 0 : resizeSidebar.width)
        height: parent.height - (offlineBanner.visible ? offlineBanner.height : 0)

        onWidthChanged: {
            console.log("StackView width changed:", width,
                       "| parent.width:", parent.width,
                       "| resizeSidebar.width:", resizeSidebar.width,
                       "| useOverlayMode:", useOverlayMode,
                       "| sidebarOpen:", sidebarOpen)
        }

        onCurrentItemChanged: {
            if (currentItem) {
                console.log("StackView currentItem changed | StackView.width:", width,
                           "| currentItem.width:", currentItem.width)
            }
        }

        // Dim when player is active
        opacity: player.isActive && player.state === "fullscreen" ? 0 : 1

        // FIX: Disable interaction when player is fullscreen
        enabled: !(player.isActive && player.state === "fullscreen")

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }

        // No initial item - we push it in onCompleted based on auth state
    }
    
    // ========================================
    // STREAM REQUEST HANDLER
    // ========================================
    
    Connections {
        target: stackView.currentItem
        ignoreUnknownSignals: true
        
        onStreamRequested: {
                player.startStream(channel, quality)
        }
    }
    
    // ========================================
    // PERSISTENT PLAYER (Top-Level, Always Exists)
    // ========================================
    
    PlayerPage {
        id: player
        // NO anchors.fill! PlayerPage manages its own size/position
        
        // Start hidden
        isActive: false
        
        onPlayerMinimized: {
            // StackView becomes visible again (opacity animation)
        }

        onPlayerMaximized: {
            // Sidebar/drawer is closed via global Connections handler
        }

        onPlayerClosed: {
            // StackView becomes visible again (opacity animation)
        }
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
        id: streamsForCategoryPage
        StreamsForCategoryPage {}
    }
    
    // ========================================
    // GLOBAL CONNECTIONS
    // ========================================
    
    Connections {
        target: authManager
        ignoreUnknownSignals: true
        
        onAuthenticationChanged: {
                
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
