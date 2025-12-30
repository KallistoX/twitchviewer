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

#ifndef TWITCHHELIXAPI_H
#define TWITCHHELIXAPI_H

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

/**
 * Twitch Helix REST API Client
 * 
 * Handles all Twitch Helix API v2 endpoints:
 * - Get Top Games/Categories
 * - Get Streams (with pagination support)
 * - Get User Info
 * - Get Followed Streams (requires OAuth)
 * 
 * Note: This is separate from GraphQL API (used for PlaybackAccessToken)
 */
class TwitchHelixAPI : public QObject
{
    Q_OBJECT

public:
    explicit TwitchHelixAPI(QObject *parent = nullptr);
    ~TwitchHelixAPI();

    // ========================================
    // PUBLIC API CALLS (no auth required)
    // ========================================
    
    /**
     * Get Top Games/Categories
     * Sorted by current viewer count
     * 
     * @param limit Number of results (max 100, default 20)
     */
    Q_INVOKABLE void getTopGames(int limit = 20);
    
    /**
     * Get Live Streams for a specific game/category
     * 
     * @param gameId Twitch Game ID
     * @param limit Number of results (max 100, default 20)
     */
    Q_INVOKABLE void getStreamsForGame(const QString &gameId, int limit = 20);
    
    /**
     * Get Live Streams for a specific game/category with pagination
     * 
     * @param gameId Twitch Game ID
     * @param limit Number of results (max 100, default 20)
     * @param cursor Pagination cursor (empty for first page)
     */
    Q_INVOKABLE void getStreamsForGameWithCursor(const QString &gameId, int limit, const QString &cursor);
    
    /**
     * Get Stream info for a specific channel
     * 
     * @param userLogin Channel name (lowercase)
     */
    Q_INVOKABLE void getStreamForUser(const QString &userLogin);
    
    // ========================================
    // AUTHENTICATED API CALLS (requires OAuth)
    // ========================================
    
    /**
     * Validate auth-token and get user info
     * This ONLY works with OAuth tokens, NOT with browser auth-token cookies!
     * 
     * @param authToken OAuth Bearer token
     */
    Q_INVOKABLE void validateAuthToken(const QString &authToken);
    
    /**
     * Get user info by login name
     * 
     * @param userLogin Username (can be multiple, comma-separated)
     */
    Q_INVOKABLE void getUserInfo(const QString &userLogin);

    /**
     * Get Followed Live Streams (requires OAuth)
     * Shows live streams from channels the authenticated user follows
     * 
     * @param userId User ID (from OAuth validation or user info)
     * @param limit Number of results (max 100, default 20)
     */
    Q_INVOKABLE void getFollowedStreams(const QString &userId, int limit = 20);

    // Set OAuth token for authenticated requests
    void setAuthToken(const QString &token) { m_authToken = token; }

signals:
    // Top Games response
    void topGamesReceived(const QJsonArray &games);
    
    // Streams response (without pagination info)
    void streamsReceived(const QJsonArray &streams);
    
    // Streams response WITH pagination info
    void streamsPaginationReceived(const QJsonArray &streams, const QString &cursor);
    
    // Single stream response
    void streamReceived(const QJsonObject &stream);
    
    // Followed streams response
    void followedStreamsReceived(const QJsonArray &streams);
    
    // User info response
    void userInfoReceived(const QJsonObject &user);
    
    // Auth validation response
    void authTokenValid(const QString &userId, const QString &login, const QString &displayName);
    void authTokenInvalid(const QString &error);
    
    // Generic error
    void error(const QString &message);

private slots:
    void onTopGamesReceived();
    void onStreamsReceived();
    void onStreamsWithPaginationReceived();
    void onFollowedStreamsReceived();
    void onUserInfoReceived();
    void onAuthValidationReceived();

private:
    QNetworkAccessManager *m_networkManager;
    QString m_authToken;
    
    // Twitch Helix API
    static const QString HELIX_BASE_URL;
    
    // Helper methods
    QNetworkRequest createRequest(const QString &endpoint, const QString &authToken = QString());
    void handleNetworkError(QNetworkReply *reply);
};

#endif // TWITCHHELIXAPI_H