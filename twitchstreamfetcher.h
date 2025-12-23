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
 
 class TwitchStreamFetcher : public QObject
 {
     Q_OBJECT
 
 public:
     explicit TwitchStreamFetcher(QObject *parent = nullptr);
     ~TwitchStreamFetcher();
 
     // Main method to fetch stream URL
     Q_INVOKABLE void fetchStreamUrl(const QString &channelName, const QString &quality = "best");
 
 signals:
     // Emitted when stream URL is ready
     void streamUrlReady(const QString &url, const QString &channelName);
     
     // Emitted when an error occurs
     void error(const QString &message);
     
     // Emitted with status updates
     void statusUpdate(const QString &status);
 
 private slots:
     // Handle GraphQL response
     void onPlaybackTokenReceived();
     
     // Handle M3U8 playlist response
     void onPlaylistReceived();
 
 private:
     // Network manager
     QNetworkAccessManager *m_networkManager;
     
     // Current request data
     QString m_currentChannel;
     QString m_requestedQuality;
     
     // Twitch API constants
     static const QString TWITCH_CLIENT_ID;
     static const QString TWITCH_GQL_URL;
     static const QString TWITCH_USHER_URL;
     static const QString PERSISTED_QUERY_HASH;
     
     // Helper methods
     void requestPlaybackToken(const QString &channelName);
     void requestPlaylist(const QString &token, const QString &signature, const QString &channelName);
     QString parseM3U8Playlist(const QString &m3u8Content, const QString &quality);
     QString extractUrlFromM3U8(const QString &m3u8Content, const QString &resolution);
 };
 
 #endif // TWITCHSTREAMFETCHER_H