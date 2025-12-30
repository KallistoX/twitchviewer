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

pragma Singleton
import QtQuick 2.15
import Lomiri.Components 1.3

QtObject {
    id: themeManager
    
    // Dark mode is default
    property bool isDarkMode: true
    
    // Color palette
    property color backgroundColor: isDarkMode ? "#1a1a1a" : "#f5f5f5"
    property color surfaceColor: isDarkMode ? "#2d2d2d" : "#ffffff"
    property color cardColor: isDarkMode ? "#383838" : "#fafafa"
    
    property color textPrimary: isDarkMode ? "#ffffff" : "#000000"
    property color textSecondary: isDarkMode ? "#b0b0b0" : "#666666"
    property color textTertiary: isDarkMode ? "#808080" : "#999999"
    
    property color accentColor: "#9146FF" // Twitch purple
    property color positiveColor: "#00c853"
    property color negativeColor: "#ff1744"
    property color warningColor: "#ffd600"
    
    property color dividerColor: isDarkMode ? "#404040" : "#e0e0e0"
    property color borderColor: isDarkMode ? "#505050" : "#d0d0d0"
    
    property color overlayColor: isDarkMode ? "#000000" : "#ffffff"
    property real overlayOpacity: isDarkMode ? 0.8 : 0.9
    
    // Initialize from settings
    Component.onCompleted: {
        if (typeof settings !== 'undefined') {
            isDarkMode = settings.value("theme/darkMode", true)
        }
    }
    
    // Toggle and save
    function toggleDarkMode() {
        isDarkMode = !isDarkMode
        saveDarkMode()
    }
    
    function saveDarkMode() {
        if (typeof settings !== 'undefined') {
            settings.setValue("theme/darkMode", isDarkMode)
        }
    }
}
