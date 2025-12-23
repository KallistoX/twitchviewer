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
 
 // Forward declaration
 class TwitchAuthManager;
 
 class TwitchStreamFetcher : public QObject
 {
     Q_OBJECT
 
     // Debug properties for displaying in Settings
     Q_PROPERTY(QString debugShowAds READ debugShowAds NOTIFY debugInfoChanged)
     Q_PROPERTY(QString debugHideAds READ debugHideAds NOTIFY debugInfoChanged)
     Q_PROPERTY(QString debugPrivileged READ debugPrivileged NOTIFY debugInfoChanged)
     Q_PROPERTY(QString debugRole READ debugRole NOTIFY debugInfoChanged)
     Q_PROPERTY(QString debugSubscriber READ debugSubscriber NOTIFY debugInfoChanged)
     Q_PROPERTY(QString debugTurbo READ debugTurbo NOTIFY debugInfoChanged)
     Q_PROPERTY(QString debugAdblock READ debugAdblock NOTIFY debugInfoChanged)
 
 public:
     explicit TwitchStreamFetcher(QObject *parent = nullptr);
     ~TwitchStreamFetcher();
 
     // Set auth manager (called from main.cpp)
     void setAuthManager(TwitchAuthManager *authManager);
 
     // Main method to fetch stream URL
     Q_INVOKABLE void fetchStreamUrl(const QString &channelName, const QString &quality = "best");
 
     // Debug property getters
     QString debugShowAds() const { return m_debugShowAds; }
     QString debugHideAds() const { return m_debugHideAds; }
     QString debugPrivileged() const { return m_debugPrivileged; }
     QString debugRole() const { return m_debugRole; }
     QString debugSubscriber() const { return m_debugSubscriber; }
     QString debugTurbo() const { return m_debugTurbo; }
     QString debugAdblock() const { return m_debugAdblock; }
 
 signals:
     // Emitted when stream URL is ready
     void streamUrlReady(const QString &url, const QString &channelName);
     
     // Emitted when an error occurs
     void error(const QString &message);
     
     // Emitted with status updates
     void statusUpdate(const QString &status);
 
     // Emitted when debug info changes
     void debugInfoChanged();
 
 private slots:
     // Handle GraphQL response
     void onPlaybackTokenReceived();
     
     // Handle M3U8 playlist response
     void onPlaylistReceived();
 
     // Handle Client-Integrity token response
     void onClientIntegrityReceived();
 
 private:
     // Network manager
     QNetworkAccessManager *m_networkManager;
     
     // Auth manager reference
     TwitchAuthManager *m_authManager;
     
     // Settings for token caching
     QSettings *m_settings;
     
     // Current request data
     QString m_currentChannel;
     QString m_requestedQuality;
     
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
     
     // Helper methods
     void requestPlaybackToken(const QString &channelName, bool withIntegrity = false);
     void requestClientIntegrity();
     void requestPlaylist(const QString &token, const QString &signature, const QString &channelName);
     QString parseM3U8Playlist(const QString &m3u8Content, const QString &quality);
     QString extractUrlFromM3U8(const QString &m3u8Content, const QString &resolution);
     void parseDebugInfo(const QString &tokenValue);
     
     // Client-Integrity helpers
     void loadClientIntegrity();
     void saveClientIntegrity();
     bool isClientIntegrityValid() const;
     QString getOrCreateDeviceId();
 };
 
 #endif // TWITCHSTREAMFETCHER_H