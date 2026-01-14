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
import Lomiri.Components 1.3

/**
 * Custom Pull to Refresh component that works reliably with Flickable
 * Replaces buggy Lomiri PullToRefresh component
 */
Item {
    id: root

    // Public properties
    property bool refreshing: false
    property real threshold: units.gu(8)  // Lower threshold for easier triggering
    property Flickable target: parent

    // Public signals
    signal refresh()

    // Internal state
    property real pullDistance: 0
    property bool isPulling: false
    property bool thresholdReached: false
    property bool refreshTriggered: false  // Track if refresh was already triggered

    // Visual state
    property string statusText: {
        if (refreshing) return i18n.tr("Refreshing...")
        if (thresholdReached) return i18n.tr("Release to refresh")
        if (isPulling) return i18n.tr("Pull to refresh")
        return ""
    }

    // Position at top
    anchors {
        left: parent ? parent.left : undefined
        right: parent ? parent.right : undefined
        top: parent ? parent.top : undefined
    }
    z: 100

    // Height based on pull distance or refresh state
    height: {
        if (refreshing) return threshold
        if (isPulling) return Math.min(pullDistance, threshold * 1.5)
        return 0
    }

    // Visual indicator
    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.background
        opacity: 0.95

        Column {
            anchors.centerIn: parent
            spacing: units.gu(1)
            visible: parent.height > units.gu(2)

            // Activity indicator / rotation icon
            Item {
                width: units.gu(4)
                height: units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter

                ActivityIndicator {
                    anchors.centerIn: parent
                    running: refreshing
                    visible: refreshing
                }

                Icon {
                    anchors.centerIn: parent
                    name: "view-refresh"
                    width: units.gu(3)
                    height: units.gu(3)
                    visible: !refreshing && isPulling
                    color: theme.palette.normal.backgroundSecondaryText

                    // Rotate based on pull progress
                    rotation: Math.min(pullDistance / threshold, 1) * 360

                    Behavior on rotation {
                        RotationAnimation {
                            duration: 100
                            direction: RotationAnimation.Shortest
                        }
                    }
                }
            }

            // Status label
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: statusText
                fontSize: "small"
                color: theme.palette.normal.backgroundSecondaryText
                visible: root.height > units.gu(6)
            }
        }
    }

    // Smooth height animation
    Behavior on height {
        NumberAnimation {
            duration: refreshing ? 200 : 100
            easing.type: Easing.OutCubic
        }
    }

    // Connection to monitor Flickable contentY changes
    Connections {
        target: root.target
        ignoreUnknownSignals: true

        function onContentYChanged() {
            if (!target) return

            // Only track pull when at the top and not refreshing
            if (target.contentY < 0 && !refreshing && !refreshTriggered) {
                // User is pulling down from top
                var pullAmount = Math.abs(target.contentY)
                pullDistance = pullAmount
                isPulling = true
                thresholdReached = pullDistance >= threshold

                console.log("Pulling: contentY=" + target.contentY + ", pullDistance=" + pullDistance + ", threshold=" + threshold + ", reached=" + thresholdReached)
            } else if (target.contentY >= 0 && !refreshTriggered) {
                // Snap back to 0 without triggering - reset state
                if (!thresholdReached) {
                    isPulling = false
                    pullDistance = 0
                }
            }
        }

        function onMovementEnded() {
            if (!target) return

            console.log("Movement ended: isPulling=" + isPulling + ", thresholdReached=" + thresholdReached + ", refreshing=" + refreshing + ", triggered=" + refreshTriggered)

            // Check if we should trigger refresh
            if (isPulling && thresholdReached && !refreshing && !refreshTriggered) {
                console.log("=== TRIGGERING REFRESH ===")
                refreshTriggered = true
                refresh()
            }

            // Reset pull state after movement ends (but keep refreshTriggered until refresh completes)
            if (!refreshing && !refreshTriggered) {
                isPulling = false
                pullDistance = 0
                thresholdReached = false
            }
        }

        function onDraggingChanged() {
            if (!target) return

            // When user stops dragging, check if we should refresh
            if (!target.dragging && isPulling && thresholdReached && !refreshing && !refreshTriggered) {
                console.log("=== TRIGGERING REFRESH ON DRAG END ===")
                refreshTriggered = true
                refresh()
            }
        }
    }

    // Reset pull distance when refreshing changes
    onRefreshingChanged: {
        if (refreshing) {
            // Refresh started - keep the indicator visible
            console.log("Refresh started")
        } else {
            // Refresh completed - reset everything
            console.log("Refresh completed - resetting state")
            pullDistance = 0
            isPulling = false
            thresholdReached = false
            refreshTriggered = false
        }
    }
}
