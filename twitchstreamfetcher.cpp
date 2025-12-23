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

 #include "twitchstreamfetcher.h"
 #include <QNetworkRequest>
 #include <QUrlQuery>
 #include <QUrl>
 #include <QDebug>
 
 // Twitch API Constants
 const QString TwitchStreamFetcher::TWITCH_CLIENT_ID = "kimne78kx3ncx6brgo4mv6wki5h1ko";
 const QString TwitchStreamFetcher::TWITCH_GQL_URL = "https://gql.twitch.tv/gql";
 const QString TwitchStreamFetcher::TWITCH_USHER_URL = "https://usher.ttvnw.net/api/channel/hls/%1.m3u8";
 const QString TwitchStreamFetcher::PERSISTED_QUERY_HASH = "0828119ded1c13477966434e15800ff57ddacf13ba1911c129dc2200705b0712";
 
 TwitchStreamFetcher::TwitchStreamFetcher(QObject *parent)
     : QObject(parent)
     , m_networkManager(new QNetworkAccessManager(this))
 {
 }
 
 TwitchStreamFetcher::~TwitchStreamFetcher()
 {
 }
 
 void TwitchStreamFetcher::fetchStreamUrl(const QString &channelName, const QString &quality)
 {
     qDebug() << "Fetching stream URL for channel:" << channelName << "quality:" << quality;
     
     m_currentChannel = channelName;
     m_requestedQuality = quality;
     
     emit statusUpdate("Connecting to Twitch...");
     requestPlaybackToken(channelName);
 }
 
 void TwitchStreamFetcher::requestPlaybackToken(const QString &channelName)
 {
    QUrl url(TWITCH_GQL_URL);
    QNetworkRequest request(url);
     request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
     request.setRawHeader("Client-ID", TWITCH_CLIENT_ID.toUtf8());
     
     // Build GraphQL query using persisted query
     QJsonObject variables;
     variables["isLive"] = true;
     variables["login"] = channelName;
     variables["isVod"] = false;
     variables["vodID"] = "";
     variables["playerType"] = "site";
     
     QJsonObject persistedQuery;
     persistedQuery["version"] = 1;
     persistedQuery["sha256Hash"] = PERSISTED_QUERY_HASH;
     
     QJsonObject extensions;
     extensions["persistedQuery"] = persistedQuery;
     
     QJsonObject payload;
     payload["operationName"] = "PlaybackAccessToken";
     payload["variables"] = variables;
     payload["extensions"] = extensions;
     
     QJsonDocument doc(payload);
     QByteArray data = doc.toJson(QJsonDocument::Compact);
     
     qDebug() << "Sending GraphQL request...";
     
     QNetworkReply *reply = m_networkManager->post(request, data);
     connect(reply, &QNetworkReply::finished, this, &TwitchStreamFetcher::onPlaybackTokenReceived);
 }
 
 void TwitchStreamFetcher::onPlaybackTokenReceived()
 {
     QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
     if (!reply) return;
     
     reply->deleteLater();
     
     if (reply->error() != QNetworkReply::NoError) {
         qWarning() << "Network error:" << reply->errorString();
         emit error("Network error: " + reply->errorString());
         return;
     }
     
     QByteArray responseData = reply->readAll();
     qDebug() << "GraphQL response received, size:" << responseData.size();
     
     QJsonDocument doc = QJsonDocument::fromJson(responseData);
     if (doc.isNull() || !doc.isObject()) {
         emit error("Invalid JSON response from Twitch");
         return;
     }
     
     QJsonObject root = doc.object();
     
     // Check for errors
     if (root.contains("errors")) {
         QJsonArray errors = root["errors"].toArray();
         if (!errors.isEmpty()) {
             QString errorMsg = errors[0].toObject()["message"].toString();
             emit error("Twitch API error: " + errorMsg);
             return;
         }
     }
     
     // Extract token and signature
     QJsonObject data = root["data"].toObject();
     QJsonObject streamPlaybackAccessToken = data["streamPlaybackAccessToken"].toObject();
     
     if (streamPlaybackAccessToken.isEmpty()) {
         emit error("Channel not found or not live: " + m_currentChannel);
         return;
     }
     
     QString token = streamPlaybackAccessToken["value"].toString();
     QString signature = streamPlaybackAccessToken["signature"].toString();
     
     if (token.isEmpty() || signature.isEmpty()) {
         emit error("Failed to get playback token");
         return;
     }
     
     qDebug() << "Got token and signature, fetching playlist...";
     emit statusUpdate("Getting stream playlist...");
     
     requestPlaylist(token, signature, m_currentChannel);
 }
 
 void TwitchStreamFetcher::requestPlaylist(const QString &token, const QString &signature, const QString &channelName)
 {
     // Build usher URL
     QString usherUrl = TWITCH_USHER_URL.arg(channelName);
     
     QUrlQuery query;
     query.addQueryItem("client_id", TWITCH_CLIENT_ID);
     query.addQueryItem("token", token);
     query.addQueryItem("sig", signature);
     query.addQueryItem("allow_source", "true");
     query.addQueryItem("allow_audio_only", "true");
     query.addQueryItem("allow_spectre", "false");
     query.addQueryItem("player", "twitchweb");
     query.addQueryItem("playlist_include_framerate", "true");
     query.addQueryItem("fast_bread", "true");
     
     QUrl url(usherUrl);
     url.setQuery(query);
     
     qDebug() << "Requesting playlist from:" << usherUrl;
     
     QNetworkRequest request(url);
     QNetworkReply *reply = m_networkManager->get(request);
     connect(reply, &QNetworkReply::finished, this, &TwitchStreamFetcher::onPlaylistReceived);
 }
 
 void TwitchStreamFetcher::onPlaylistReceived()
 {
     QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
     if (!reply) return;
     
     reply->deleteLater();
     
     if (reply->error() != QNetworkReply::NoError) {
         qWarning() << "Network error getting playlist:" << reply->errorString();
         emit error("Failed to get playlist: " + reply->errorString());
         return;
     }
     
     QString m3u8Content = QString::fromUtf8(reply->readAll());
     qDebug() << "Playlist received, size:" << m3u8Content.size();
     
     if (m3u8Content.isEmpty() || !m3u8Content.contains("#EXTM3U")) {
         emit error("Invalid playlist received");
         return;
     }
     
     // Parse playlist and extract URL
     QString streamUrl = parseM3U8Playlist(m3u8Content, m_requestedQuality);
     
     if (streamUrl.isEmpty()) {
         emit error("Failed to parse stream URL from playlist");
         return;
     }

     qDebug() << "Stream URL ready:" << streamUrl.left(80) << "...";
    qDebug() << "Emitting statusUpdate signal";
    emit statusUpdate("Stream ready!");
    qDebug() << "Emitting streamUrlReady signal with channel:" << m_currentChannel;
    emit streamUrlReady(streamUrl, m_currentChannel);
    qDebug() << "Signals emitted successfully";
 }
 
 QString TwitchStreamFetcher::parseM3U8Playlist(const QString &m3u8Content, const QString &quality)
 {
     QStringList lines = m3u8Content.split('\n');
     
     // Quality mapping
     QMap<QString, QString> qualityMap;
     qualityMap["best"] = "1080p";
     qualityMap["source"] = "1080p";
     qualityMap["high"] = "720p";
     qualityMap["medium"] = "480p";
     qualityMap["low"] = "360p";
     qualityMap["mobile"] = "160p";
     
     QString targetResolution = qualityMap.value(quality.toLower(), "1080p");
     
     qDebug() << "Looking for quality:" << quality << "-> resolution:" << targetResolution;
     
     // First, try to find exact match
     QString url = extractUrlFromM3U8(m3u8Content, targetResolution);
     if (!url.isEmpty()) {
         return url;
     }
     
     // If not found, return the first (best) quality
     for (int i = 0; i < lines.size(); i++) {
         QString line = lines[i].trimmed();
         
         if (line.startsWith("#EXT-X-STREAM-INF")) {
             // Next line should be the URL
             if (i + 1 < lines.size()) {
                 QString nextLine = lines[i + 1].trimmed();
                 if (nextLine.startsWith("http")) {
                     qDebug() << "Using first available quality";
                     return nextLine;
                 }
             }
         }
     }
     
     return QString();
 }
 
 QString TwitchStreamFetcher::extractUrlFromM3U8(const QString &m3u8Content, const QString &resolution)
 {
     QStringList lines = m3u8Content.split('\n');
     
     for (int i = 0; i < lines.size(); i++) {
         QString line = lines[i].trimmed();
         
         if (line.startsWith("#EXT-X-STREAM-INF")) {
             // Check if this line contains our desired resolution
             if (line.contains(resolution, Qt::CaseInsensitive) || 
                 line.contains("RESOLUTION=1920x1080") && resolution.contains("1080") ||
                 line.contains("RESOLUTION=1280x720") && resolution.contains("720") ||
                 line.contains("RESOLUTION=852x480") && resolution.contains("480") ||
                 line.contains("RESOLUTION=640x360") && resolution.contains("360") ||
                 line.contains("RESOLUTION=284x160") && resolution.contains("160")) {
                 
                 // Next line should be the URL
                 if (i + 1 < lines.size()) {
                     QString nextLine = lines[i + 1].trimmed();
                     if (nextLine.startsWith("http")) {
                         qDebug() << "Found matching quality:" << resolution;
                         return nextLine;
                     }
                 }
             }
         }
     }
     
     return QString();
 }