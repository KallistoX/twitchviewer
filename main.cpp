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
#include "twitchauthmanager.h"
#include "twitchhelixapi.h"

int main(int argc, char *argv[])
{
    QGuiApplication *app = new QGuiApplication(argc, (char**)argv);
    app->setApplicationName("twitchviewer.kallisto-app");

    qDebug() << "Starting TwitchViewer...";

    // Create auth manager
    TwitchAuthManager *authManager = new TwitchAuthManager(app);
    qDebug() << "TwitchAuthManager created";

    // Create Twitch stream fetcher
    TwitchStreamFetcher *streamFetcher = new TwitchStreamFetcher(app);
    streamFetcher->setAuthManager(authManager);
    qDebug() << "TwitchStreamFetcher created and auth manager linked";

    // Create Helix API client
    TwitchHelixAPI *helixApi = new TwitchHelixAPI(app);
    qDebug() << "TwitchHelixAPI created";

    QQuickView *view = new QQuickView();
    
    // Make all available in QML
    view->rootContext()->setContextProperty("authManager", authManager);
    view->rootContext()->setContextProperty("twitchFetcher", streamFetcher);
    view->rootContext()->setContextProperty("helixApi", helixApi);
    
    qDebug() << "Context properties set";
    
    view->setSource(QUrl("qrc:/Main.qml"));
    view->setResizeMode(QQuickView::SizeRootObjectToView);
    view->show();

    qDebug() << "View shown, entering event loop";

    return app->exec();
}