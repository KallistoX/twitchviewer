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

#include <QGuiApplication>
#include <QCoreApplication>
#include <QUrl>
#include <QString>
#include <QQuickView>
#include <QQmlContext>
#include "twitchstreamfetcher.h"
#include "src/auth/twitchauthmanager.h"
#include "src/api/twitchhelixapi.h"
#include "src/network/networkmanager.h"
#include "src/core/logging.h"

int main(int argc, char *argv[])
{
    QGuiApplication *app = new QGuiApplication(argc, (char**)argv);
    app->setApplicationName("twitchviewer.kallisto-app");

    LOG_APP("Application starting");

    // Create network manager
    NetworkManager *networkManager = new NetworkManager(app);

    // Create auth manager
    TwitchAuthManager *authManager = new TwitchAuthManager(app);
    authManager->setNetworkManager(networkManager);

    // Create Twitch stream fetcher
    TwitchStreamFetcher *streamFetcher = new TwitchStreamFetcher(app);
    streamFetcher->setAuthManager(authManager);
    streamFetcher->setNetworkManager(networkManager);

    // Create Helix API
    TwitchHelixAPI *helixApi = new TwitchHelixAPI(app);
    helixApi->setNetworkManager(networkManager);

    // Sync OAuth token to Helix API
    QObject::connect(authManager, &TwitchAuthManager::authenticationChanged,
        [helixApi, authManager](bool authenticated) {
            if (authenticated) {
                helixApi->setAuthToken(authManager->accessToken());
            } else {
                helixApi->setAuthToken("");
            }
        });

    // Also sync on token refresh
    QObject::connect(authManager, &TwitchAuthManager::tokenRefreshed,
        [helixApi, authManager]() {
            helixApi->setAuthToken(authManager->accessToken());
        });

    // Set initial token if already authenticated
    if (authManager->isAuthenticated()) {
        helixApi->setAuthToken(authManager->accessToken());
    }

    QQuickView *view = new QQuickView();

    // Make all available in QML
    view->rootContext()->setContextProperty("networkManager", networkManager);
    view->rootContext()->setContextProperty("authManager", authManager);
    view->rootContext()->setContextProperty("twitchFetcher", streamFetcher);
    view->rootContext()->setContextProperty("helixApi", helixApi);

    view->setSource(QUrl("qrc:/Main.qml"));
    view->setResizeMode(QQuickView::SizeRootObjectToView);
    view->show();

    return app->exec();
}