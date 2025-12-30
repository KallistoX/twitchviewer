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
#include "config.h"
#include <QNetworkRequest>
#include <QUrlQuery>
#include <QUrl>
#include <QDebug>

const QString TwitchHelixAPI::HELIX_BASE_URL = "https://api.twitch.tv/helix";

TwitchHelixAPI::TwitchHelixAPI(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_authToken("")
{
    qDebug() << "TwitchHelixAPI initialized";
}

TwitchHelixAPI::~TwitchHelixAPI()
{
}

// ========================================
// PUBLIC API CALLS
// ========================================

void TwitchHelixAPI::getTopGames(int limit)
{
    qDebug() << "Getting top games, limit:" << limit;
    
    // Clamp limit
    if (limit > 100) limit = 100;
    if (limit < 1) limit = 1;
    
    QString endpoint = QString("/games/top?first=%1").arg(limit);
    
    // Use cached auth token if available
    QNetworkRequest request = createRequest(endpoint, m_authToken);
    
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, &TwitchHelixAPI::onTopGamesReceived);
}

void TwitchHelixAPI::getStreamsForGame(const QString &gameId, int limit)
{
    qDebug() << "Getting streams for game:" << gameId << "limit:" << limit;
    
    // Clamp limit
    if (limit > 100) limit = 100;
    if (limit < 1) limit = 1;
    
    QString endpoint = QString("/streams?game_id=%1&first=%2&type=live").arg(gameId).arg(limit);
    QNetworkRequest request = createRequest(endpoint, m_authToken);
    
    QNetworkReply *reply = m_networkManager->get(request);
    
    // Mark as non-pagination request
    reply->setProperty("withPagination", false);
    
    connect(reply, &QNetworkReply::finished, this, &TwitchHelixAPI::onStreamsReceived);
}

void TwitchHelixAPI::getStreamsForGameWithCursor(const QString &gameId, int limit, const QString &cursor)
{
    qDebug() << "Getting streams for game with cursor:" << gameId << "limit:" << limit << "cursor:" << cursor;
    
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
    
    // Mark as pagination request
    reply->setProperty("withPagination", true);
    
    connect(reply, &QNetworkReply::finished, this, &TwitchHelixAPI::onStreamsWithPaginationReceived);
}

void TwitchHelixAPI::getStreamForUser(const QString &userLogin)
{
    qDebug() << "Getting stream for user:" << userLogin;
    
    QString endpoint = QString("/streams?user_login=%1").arg(userLogin);
    QNetworkRequest request = createRequest(endpoint, m_authToken);
    
    QNetworkReply *reply = m_networkManager->get(request);
    
    // Mark as non-pagination request
    reply->setProperty("withPagination", false);
    
    connect(reply, &QNetworkReply::finished, this, &TwitchHelixAPI::onStreamsReceived);
}

void TwitchHelixAPI::getUserInfo(const QString &userLogin)
{
    qDebug() << "Getting user info for:" << userLogin;
    
    QString endpoint = QString("/users?login=%1").arg(userLogin);
    QNetworkRequest request = createRequest(endpoint, m_authToken);
    
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, &TwitchHelixAPI::onUserInfoReceived);
}

void TwitchHelixAPI::getFollowedStreams(const QString &userId, int limit)
{
    qDebug() << "Getting followed streams for user ID:" << userId << "limit:" << limit;
    
    // IMPORTANT: Requires OAuth token with user:read:follows scope
    if (m_authToken.isEmpty()) {
        qWarning() << "Cannot get followed streams without OAuth token";
        emit error("Authentication required to view followed streams");
        return;
    }
    
    // Clamp limit
    if (limit > 100) limit = 100;
    if (limit < 1) limit = 1;
    
    QString endpoint = QString("/streams/followed?user_id=%1&first=%2").arg(userId).arg(limit);
    QNetworkRequest request = createRequest(endpoint, m_authToken);
    
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, &TwitchHelixAPI::onFollowedStreamsReceived);
}

void TwitchHelixAPI::validateAuthToken(const QString &authToken)
{
    qDebug() << "Validating auth token...";
    
    QUrl url("https://id.twitch.tv/oauth2/validate");
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QString("OAuth %1").arg(authToken).toUtf8());
    
    QNetworkReply *reply = m_networkManager->get(request);
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
    
    qDebug() << "Received" << games.size() << "top games";
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
    
    qDebug() << "Received" << streams.size() << "streams";
    
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
    
    qDebug() << "Received" << streams.size() << "streams with pagination";
    qDebug() << "Next cursor:" << (cursor.isEmpty() ? "NONE (last page)" : cursor);
    
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
    
    qDebug() << "Received" << streams.size() << "followed streams";
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
    qDebug() << "Received user info for:" << user["login"].toString();
    
    emit userInfoReceived(user);
}

void TwitchHelixAPI::onAuthValidationReceived()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    reply->deleteLater();
    
    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Auth validation failed:" << reply->errorString();
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
    
    qDebug() << "✅ Auth token valid for user:" << login;
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
        qDebug() << "Helix API: Using custom Client-ID with OAuth token";
    } else {
        // Without OAuth: Use public Client-ID for anonymous requests
        request.setRawHeader("Client-ID", Config::TWITCH_PUBLIC_CLIENT_ID.toUtf8());
        qDebug() << "Helix API: Using public Client-ID (anonymous)";
    }
    
    return request;
}

void TwitchHelixAPI::handleNetworkError(QNetworkReply *reply)
{
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QString errorString = reply->errorString();
    
    qWarning() << "Network error:" << errorString;
    qWarning() << "HTTP status code:" << statusCode;
    
    // Read response body for more details
    QByteArray errorBody = reply->readAll();
    if (!errorBody.isEmpty()) {
        qWarning() << "Error response:" << errorBody;
    }
    
    emit error(QString("Network error: %1 (HTTP %2)").arg(errorString).arg(statusCode));
}