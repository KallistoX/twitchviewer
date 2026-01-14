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

 #ifndef TWITCHSTREAMFETCHER_H
 #define TWITCHSTREAMFETCHER_H
 
 #include <QObject>
 #include <QString>
 #include <QNetworkAccessManager>
 #include <QNetworkReply>
 #include <QJsonDocument>
 #include <QJsonObject>
 #include <QJsonArray>
 #include <QUrlQuery>
 #include <QDateTime>
 #include <QUuid>
 #include <QSettings>
 #include <QTimer>
 #include <QMap>
 
 // Forward declaration
 class TwitchAuthManager;
 class NetworkManager;
 
 class TwitchStreamFetcher : public QObject
 {
     Q_OBJECT

     // User Info Properties
     Q_PROPERTY(QString currentUserId READ currentUserId NOTIFY currentUserChanged)
     Q_PROPERTY(QString currentUserLogin READ currentUserLogin NOTIFY currentUserChanged)
     Q_PROPERTY(QString currentUserDisplayName READ currentUserDisplayName NOTIFY currentUserChanged)
     Q_PROPERTY(QString currentUserProfileImage READ currentUserProfileImage NOTIFY currentUserChanged)
     Q_PROPERTY(bool hasUserInfo READ hasUserInfo NOTIFY currentUserChanged)
 
     // Debug properties for displaying in Settings
     Q_PROPERTY(QString debugShowAds READ debugShowAds NOTIFY debugInfoChanged)
     Q_PROPERTY(QString debugHideAds READ debugHideAds NOTIFY debugInfoChanged)
     Q_PROPERTY(QString debugPrivileged READ debugPrivileged NOTIFY debugInfoChanged)
     Q_PROPERTY(QString debugRole READ debugRole NOTIFY debugInfoChanged)
     Q_PROPERTY(QString debugSubscriber READ debugSubscriber NOTIFY debugInfoChanged)
     Q_PROPERTY(QString debugTurbo READ debugTurbo NOTIFY debugInfoChanged)
     Q_PROPERTY(QString debugAdblock READ debugAdblock NOTIFY debugInfoChanged)
 
     // GraphQL Token Management
     Q_PROPERTY(bool hasGraphQLToken READ hasGraphQLToken NOTIFY graphQLTokenChanged)
     Q_PROPERTY(bool isValidatingToken READ isValidatingToken NOTIFY validatingTokenChanged)
 
 public:
     explicit TwitchStreamFetcher(QObject *parent = nullptr);
     ~TwitchStreamFetcher();
 
     // Set auth manager (called from main.cpp)
     void setAuthManager(TwitchAuthManager *authManager);
 
     // Main method to fetch stream URL
     Q_INVOKABLE void fetchStreamUrl(const QString &channelName, const QString &quality = "best");
 
     // Get available qualities from last fetched playlist
     Q_INVOKABLE QStringList getAvailableQualities() const { return m_availableQualities; }
     Q_INVOKABLE QString getQualityUrl(const QString &quality) const;

     // GraphQL Token Management
     Q_INVOKABLE void setGraphQLToken(const QString &token);
     Q_INVOKABLE void clearGraphQLToken();
     Q_INVOKABLE void validateGraphQLToken();
     Q_INVOKABLE QString getGraphQLToken() const { return m_graphQLToken; }
 
     // User Info
     Q_INVOKABLE void fetchCurrentUser();
     
     // Fetch top categories using GraphQL (anonymous, no auth required)
     Q_INVOKABLE void fetchTopCategoriesGraphQL(int limit = 30);
     
     // User Info property getters
     QString currentUserId() const { return m_currentUserId; }
     QString currentUserLogin() const { return m_currentUserLogin; }
     QString currentUserDisplayName() const { return m_currentUserDisplayName; }
     QString currentUserProfileImage() const { return m_currentUserProfileImage; }
     bool hasUserInfo() const { return !m_currentUserId.isEmpty(); }

     // Debug property getters
     QString debugShowAds() const { return m_debugShowAds; }
     QString debugHideAds() const { return m_debugHideAds; }
     QString debugPrivileged() const { return m_debugPrivileged; }
     QString debugRole() const { return m_debugRole; }
     QString debugSubscriber() const { return m_debugSubscriber; }
     QString debugTurbo() const { return m_debugTurbo; }
     QString debugAdblock() const { return m_debugAdblock; }
 
     // GraphQL Token property getters
     bool hasGraphQLToken() const { return !m_graphQLToken.isEmpty(); }
     bool isValidatingToken() const { return m_isValidatingToken; }

     void setNetworkManager(NetworkManager *networkManager);
 
 signals:
     // Emitted when stream URL is ready
     void streamUrlReady(const QString &url, const QString &channelName);
     
     // Emitted when available qualities are ready
     void availableQualitiesChanged(const QStringList &qualities);
     
     // Emitted when an error occurs
     void error(const QString &message);
     
     // Emitted with status updates
     void statusUpdate(const QString &status);

     // Emitted when current user info changes
     void currentUserChanged();
 
     // Emitted when debug info changes
     void debugInfoChanged();
 
     // Emitted when GraphQL token changes
     void graphQLTokenChanged();
     
     // Emitted when token validation state changes
     void validatingTokenChanged();
     
     // Emitted when token validation completes
     void tokenValidationSuccess(const QString &message);
     void tokenValidationFailed(const QString &message);
 
     // Emitted when top categories are received (GraphQL)
     void topCategoriesReceived(const QJsonArray &categories);
 
 private slots:
     // Handle GraphQL response
     void onPlaybackTokenReceived();
     
     // Handle M3U8 playlist response
     void onPlaylistReceived();
 
     // Handle Client-Integrity token response
     void onClientIntegrityReceived();
 
     // Handle token validation response (old method - still used)
     void onTokenValidationReceived();

     // Handle user info response (UserMenuCurrentUser query)
     void onUserInfoReceived();
 
     // Handle top categories response (BrowsePage_AllDirectories query)
     void onTopCategoriesReceived();

     // Handle request timeout
     void onRequestTimeout();

 private:
     // Network manager
     QNetworkAccessManager *m_networkManager;

     // Auth manager reference
     TwitchAuthManager *m_authManager;

     // Settings for token caching
     QSettings *m_settings;

     // Request timeout management
     QMap<QNetworkReply*, QTimer*> m_timeoutTimers;
     static const int REQUEST_TIMEOUT_MS = 15000; // 15 seconds

     // Current request data
     QString m_currentChannel;
     QString m_requestedQuality;
     bool m_isValidatingToken;
     
     // Quality caching (from last M3U8 playlist)
     QMap<QString, QString> m_qualityUrls;  // quality name -> URL
     QStringList m_availableQualities;      // ordered list
     
     // Current user info
     QString m_currentUserId;
     QString m_currentUserLogin;
     QString m_currentUserDisplayName;
     QString m_currentUserProfileImage;
     
     // GraphQL Token (from browser cookie)
     QString m_graphQLToken;
     
     // Client-Integrity token (cached)
     QString m_clientIntegrityToken;
     QDateTime m_clientIntegrityExpiration;
     QString m_deviceId;
     
     // Debug info (from last fetch)
     QString m_debugShowAds;
     QString m_debugHideAds;
     QString m_debugPrivileged;
     QString m_debugRole;
     QString m_debugSubscriber;
     QString m_debugTurbo;
     QString m_debugAdblock;
     
     // Twitch API constants
     static const QString TWITCH_GQL_URL;
     static const QString TWITCH_INTEGRITY_URL;
     static const QString TWITCH_USHER_URL;
     static const QString PERSISTED_QUERY_HASH;
     static const QString PERSISTED_QUERY_HASH_USER;
     static const QString PERSISTED_QUERY_HASH_CATEGORIES;
     
     // Helper methods
     void requestPlaybackToken(const QString &channelName, bool withIntegrity = false);
     void requestClientIntegrity();
     void requestPlaylist(const QString &token, const QString &signature, const QString &channelName);
     void requestUserInfo();
     void requestUserDetails(const QString &userId);
     void requestTopCategories(int limit);
     QString parseM3U8Playlist(const QString &m3u8Content, const QString &quality);
     QString extractUrlFromM3U8(const QString &m3u8Content, const QString &resolution);
     void parseDebugInfo(const QString &tokenValue);
     
     // Client-Integrity helpers
     void loadClientIntegrity();
     void saveClientIntegrity();
     bool isClientIntegrityValid() const;
     QString getOrCreateDeviceId();
     
     // GraphQL Token helpers
     void loadGraphQLToken();
     void saveGraphQLToken();

     // Request timeout helpers
     void setupRequestTimeout(QNetworkReply *reply);
     void cleanupRequest(QNetworkReply *reply);

     NetworkManager *m_netStatusManager;
 };
 
 #endif // TWITCHSTREAMFETCHER_H