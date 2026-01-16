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

#include "twitchhelixapi.h"
#include "../core/config.h"
#include "../core/logging.h"
#include <QNetworkRequest>
#include <QUrlQuery>
#include <QUrl>
#include "../network/networkmanager.h"

const QString TwitchHelixAPI::HELIX_BASE_URL = "https://api.twitch.tv/helix";

TwitchHelixAPI::TwitchHelixAPI(QObject *parent)
    : QObject(parent)
    , m_netStatusManager(nullptr)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_authToken("")
{
}

TwitchHelixAPI::~TwitchHelixAPI()
{
}

// ========================================
// PUBLIC API CALLS
// ========================================

void TwitchHelixAPI::getTopGames(int limit)
{
    
    // Clamp limit
    if (limit > 100) limit = 100;
    if (limit < 1) limit = 1;
    
    QString endpoint = QString("/games/top?first=%1").arg(limit);
    
    // Use cached auth token if available
    QNetworkRequest request = createRequest(endpoint, m_authToken);
    
    QNetworkReply *reply = m_networkManager->get(request);
    setupRequestTimeout(reply);
    connect(reply, &QNetworkReply::finished, this, &TwitchHelixAPI::onTopGamesReceived);
}

void TwitchHelixAPI::getStreamsForGame(const QString &gameId, int limit)
{
    
    // Clamp limit
    if (limit > 100) limit = 100;
    if (limit < 1) limit = 1;
    
    QString endpoint = QString("/streams?game_id=%1&first=%2&type=live").arg(gameId).arg(limit);
    QNetworkRequest request = createRequest(endpoint, m_authToken);
    
    QNetworkReply *reply = m_networkManager->get(request);
    setupRequestTimeout(reply);
    
    // Mark as non-pagination request
    reply->setProperty("withPagination", false);
    
    connect(reply, &QNetworkReply::finished, this, &TwitchHelixAPI::onStreamsReceived);
}

void TwitchHelixAPI::getStreamsForGameWithCursor(const QString &gameId, int limit, const QString &cursor)
{
    
    // Clamp limit
    if (limit > 100) limit = 100;
    if (limit < 1) limit = 1;
    
    QString endpoint = QString("/streams?game_id=%1&first=%2&type=live").arg(gameId).arg(limit);
    
    // Add cursor if provided
    if (!cursor.isEmpty()) {
        endpoint += QString("&after=%1").arg(cursor);
    }
    
    QNetworkRequest request = createRequest(endpoint, m_authToken);
    
    QNetworkReply *reply = m_networkManager->get(request);
    setupRequestTimeout(reply);
    
    // Mark as pagination request
    reply->setProperty("withPagination", true);
    
    connect(reply, &QNetworkReply::finished, this, &TwitchHelixAPI::onStreamsWithPaginationReceived);
}

void TwitchHelixAPI::getStreamForUser(const QString &userLogin)
{
    
    QString endpoint = QString("/streams?user_login=%1").arg(userLogin);
    QNetworkRequest request = createRequest(endpoint, m_authToken);
    
    QNetworkReply *reply = m_networkManager->get(request);
    setupRequestTimeout(reply);
    
    // Mark as non-pagination request
    reply->setProperty("withPagination", false);
    
    connect(reply, &QNetworkReply::finished, this, &TwitchHelixAPI::onStreamsReceived);
}

void TwitchHelixAPI::getUserInfo(const QString &userLogin)
{
    
    QString endpoint = QString("/users?login=%1").arg(userLogin);
    QNetworkRequest request = createRequest(endpoint, m_authToken);
    
    QNetworkReply *reply = m_networkManager->get(request);
    setupRequestTimeout(reply);
    connect(reply, &QNetworkReply::finished, this, &TwitchHelixAPI::onUserInfoReceived);
}

void TwitchHelixAPI::getFollowedStreams(const QString &userId, int limit)
{
    
    // IMPORTANT: Requires OAuth token with user:read:follows scope
    if (m_authToken.isEmpty()) {
        WARN_API("Cannot get followed streams without OAuth token");
        emit error("Authentication required to view followed streams");
        return;
    }
    
    // Clamp limit
    if (limit > 100) limit = 100;
    if (limit < 1) limit = 1;
    
    QString endpoint = QString("/streams/followed?user_id=%1&first=%2").arg(userId).arg(limit);
    QNetworkRequest request = createRequest(endpoint, m_authToken);

    QNetworkReply *reply = m_networkManager->get(request);
    setupRequestTimeout(reply);
    connect(reply, &QNetworkReply::finished, this, &TwitchHelixAPI::onFollowedStreamsReceived);
}

void TwitchHelixAPI::setNetworkManager(NetworkManager *networkManager)
{
    m_netStatusManager = networkManager;
}

void TwitchHelixAPI::validateAuthToken(const QString &authToken)
{
    
    QUrl url("https://id.twitch.tv/oauth2/validate");
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QString("OAuth %1").arg(authToken).toUtf8());
    
    QNetworkReply *reply = m_networkManager->get(request);
    setupRequestTimeout(reply);
    connect(reply, &QNetworkReply::finished, this, &TwitchHelixAPI::onAuthValidationReceived);
}

// ========================================
// RESPONSE HANDLERS
// ========================================

void TwitchHelixAPI::onTopGamesReceived()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    reply->deleteLater();
    
    if (reply->error() != QNetworkReply::NoError) {
        handleNetworkError(reply);
        return;
    }
    
    QByteArray responseData = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(responseData);
    
    if (doc.isNull() || !doc.isObject()) {
        emit error("Invalid JSON response");
        return;
    }
    
    QJsonObject obj = doc.object();
    QJsonArray games = obj["data"].toArray();

    // Report successful network request
    if (m_netStatusManager) {
        m_netStatusManager->reportSuccess();
    }

    emit topGamesReceived(games);
}

void TwitchHelixAPI::onStreamsReceived()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    reply->deleteLater();
    
    if (reply->error() != QNetworkReply::NoError) {
        handleNetworkError(reply);
        return;
    }
    
    QByteArray responseData = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(responseData);
    
    if (doc.isNull() || !doc.isObject()) {
        emit error("Invalid JSON response");
        return;
    }
    
    QJsonObject obj = doc.object();
    QJsonArray streams = obj["data"].toArray();

    // Report successful network request
    if (m_netStatusManager) {
        m_netStatusManager->reportSuccess();
    }

    // If single stream request, emit single stream
    if (streams.size() == 1) {
        emit streamReceived(streams[0].toObject());
    } else {
        emit streamsReceived(streams);
    }
}

void TwitchHelixAPI::onStreamsWithPaginationReceived()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    reply->deleteLater();
    
    if (reply->error() != QNetworkReply::NoError) {
        handleNetworkError(reply);
        return;
    }
    
    QByteArray responseData = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(responseData);
    
    if (doc.isNull() || !doc.isObject()) {
        emit error("Invalid JSON response");
        return;
    }
    
    QJsonObject obj = doc.object();
    QJsonArray streams = obj["data"].toArray();
    
    // Extract pagination cursor
    QString cursor = "";
    if (obj.contains("pagination")) {
        QJsonObject pagination = obj["pagination"].toObject();
        cursor = pagination["cursor"].toString();
    }

    // Report successful network request
    if (m_netStatusManager) {
        m_netStatusManager->reportSuccess();
    }

    emit streamsPaginationReceived(streams, cursor);
}

void TwitchHelixAPI::onFollowedStreamsReceived()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    reply->deleteLater();
    
    if (reply->error() != QNetworkReply::NoError) {
        handleNetworkError(reply);
        return;
    }
    
    QByteArray responseData = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(responseData);
    
    if (doc.isNull() || !doc.isObject()) {
        emit error("Invalid JSON response");
        return;
    }
    
    QJsonObject obj = doc.object();
    QJsonArray streams = obj["data"].toArray();

    // Report successful network request
    if (m_netStatusManager) {
        m_netStatusManager->reportSuccess();
    }

    emit followedStreamsReceived(streams);
}

void TwitchHelixAPI::onUserInfoReceived()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    reply->deleteLater();
    
    if (reply->error() != QNetworkReply::NoError) {
        handleNetworkError(reply);
        return;
    }
    
    QByteArray responseData = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(responseData);
    
    if (doc.isNull() || !doc.isObject()) {
        emit error("Invalid JSON response");
        return;
    }
    
    QJsonObject obj = doc.object();
    QJsonArray users = obj["data"].toArray();
    
    if (users.isEmpty()) {
        emit error("User not found");
        return;
    }
    
    QJsonObject user = users[0].toObject();

    // Report successful network request
    if (m_netStatusManager) {
        m_netStatusManager->reportSuccess();
    }

    emit userInfoReceived(user);
}

void TwitchHelixAPI::onAuthValidationReceived()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    reply->deleteLater();
    
    if (reply->error() != QNetworkReply::NoError) {
        WARN_API("Auth validation failed:" << reply->errorString());
        emit authTokenInvalid(reply->errorString());
        return;
    }
    
    QByteArray responseData = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(responseData);
    
    if (doc.isNull() || !doc.isObject()) {
        emit authTokenInvalid("Invalid response");
        return;
    }
    
    QJsonObject obj = doc.object();
    
    QString userId = obj["user_id"].toString();
    QString login = obj["login"].toString();
    
    if (userId.isEmpty() || login.isEmpty()) {
        emit authTokenInvalid("Invalid token data");
        return;
    }
    
    // Report successful network request
    if (m_netStatusManager) {
        m_netStatusManager->reportSuccess();
    }

    LOG_API("Token valid for user:" << login);
    emit authTokenValid(userId, login, login); // displayName = login for now
}

// ========================================
// HELPER METHODS
// ========================================

QNetworkRequest TwitchHelixAPI::createRequest(const QString &endpoint, const QString &authToken)
{
    QUrl url(HELIX_BASE_URL + endpoint);
    QNetworkRequest request(url);
    
    // CRITICAL: Client-ID must match the token's origin!
    if (!authToken.isEmpty()) {
        // With OAuth: Use our custom Client-ID (token was generated with this)
        request.setRawHeader("Client-ID", Config::TWITCH_CLIENT_ID.toUtf8());
        request.setRawHeader("Authorization", QString("Bearer %1").arg(authToken).toUtf8());
        } else {
        // Without OAuth: Use public Client-ID for anonymous requests
        request.setRawHeader("Client-ID", Config::TWITCH_PUBLIC_CLIENT_ID.toUtf8());
        }
    
    return request;
}

void TwitchHelixAPI::handleNetworkError(QNetworkReply *reply)
{
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QString errorString = reply->errorString();


    // Read response body for more details
    QByteArray errorBody = reply->readAll();
    if (!errorBody.isEmpty()) {
        WARN_API("Error:" << errorBody);
    }

    // Classify and report error to NetworkManager
    if (m_netStatusManager) {
        NetworkManager::ErrorType errorType = m_netStatusManager->classifyError(reply);
        }

    emit error(QString("Network error: %1 (HTTP %2)").arg(errorString).arg(statusCode));
}
// ========================================
// REQUEST TIMEOUT MANAGEMENT
// ========================================

const int TwitchHelixAPI::REQUEST_TIMEOUT_MS;

void TwitchHelixAPI::setupRequestTimeout(QNetworkReply *reply)
{
    if (!reply) return;

    // Don't setup timeout twice for the same reply
    if (m_timeoutTimers.contains(reply)) {
        WARN_API("Timeout already set");
        return;
    }

    // Create timeout timer
    QTimer *timer = new QTimer(this);
    timer->setSingleShot(true);
    timer->setInterval(REQUEST_TIMEOUT_MS);

    // Store the reply pointer in the timer
    timer->setProperty("reply", QVariant::fromValue(reply));

    // Connect timeout
    connect(timer, &QTimer::timeout, this, &TwitchHelixAPI::onRequestTimeout);

    // Cleanup timer when request finishes (use QueuedConnection to be safe)
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        cleanupRequest(reply);
    }, Qt::QueuedConnection);

    // Also cleanup when reply is destroyed
    connect(reply, &QObject::destroyed, this, [this, reply]() {
        if (m_timeoutTimers.contains(reply)) {
            QTimer *timer = m_timeoutTimers.value(reply);
            if (timer) {
                timer->stop();
                timer->deleteLater();
            }
            m_timeoutTimers.remove(reply);
        }
    });

    // Start timer
    m_timeoutTimers[reply] = timer;
    timer->start();

}

void TwitchHelixAPI::onRequestTimeout()
{
    QTimer *timer = qobject_cast<QTimer*>(sender());
    if (!timer) return;

    // Get the reply from the timer property
    QNetworkReply *reply = timer->property("reply").value<QNetworkReply*>();

    if (reply && m_timeoutTimers.contains(reply)) {
        WARN_API("Request timed out");

        // Notify NetworkManager about the timeout (treated as network error)
        if (m_netStatusManager) {
            m_netStatusManager->reportError(NetworkManager::NetworkError);
    
        }

        // Abort the request
        reply->abort();

        // Cleanup will happen in the finished() handler
    }
}

void TwitchHelixAPI::cleanupRequest(QNetworkReply *reply)
{
    if (!reply) return;

    // Stop and delete timer if it exists
    if (m_timeoutTimers.contains(reply)) {
        QTimer *timer = m_timeoutTimers.value(reply);
        if (timer) {
            timer->stop();
            timer->deleteLater();
        }
        m_timeoutTimers.remove(reply);
    }
}
