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
 #include "twitchauthmanager.h"
 #include "config.h"
 #include <QNetworkRequest>
 #include <QUrlQuery>
 #include <QUrl>
 #include <QDebug>
 #include <QStandardPaths>
 #include <QDir>
 
 // Twitch API Constants
 const QString TwitchStreamFetcher::TWITCH_GQL_URL = "https://gql.twitch.tv/gql";
 const QString TwitchStreamFetcher::TWITCH_INTEGRITY_URL = "https://gql.twitch.tv/integrity";
 const QString TwitchStreamFetcher::TWITCH_USHER_URL = "https://usher.ttvnw.net/api/channel/hls/%1.m3u8";
 const QString TwitchStreamFetcher::PERSISTED_QUERY_HASH = "0828119ded1c13477966434e15800ff57ddacf13ba1911c129dc2200705b0712";
 const QString TwitchStreamFetcher::PERSISTED_QUERY_HASH_USER = "3cff634f43c5c78830907a662b315b1847cfc0dce32e6a9752e7f5d70b37f8c0";
 
 TwitchStreamFetcher::TwitchStreamFetcher(QObject *parent)
     : QObject(parent)
     , m_networkManager(new QNetworkAccessManager(this))
     , m_authManager(nullptr)
     , m_isValidatingToken(false)
     , m_debugShowAds("N/A")
     , m_debugHideAds("N/A")
     , m_debugPrivileged("N/A")
     , m_debugRole("N/A")
     , m_debugSubscriber("N/A")
     , m_debugTurbo("N/A")
     , m_debugAdblock("N/A")
 {
     // CRITICAL FIX: Use AppDataLocation for Ubuntu Touch confinement
     QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
     
     // Ensure directory exists
     QDir().mkpath(dataPath);
     
     QString settingsFile = dataPath + "/twitchviewer.conf";
     m_settings = new QSettings(settingsFile, QSettings::NativeFormat, this);
     
     qDebug() << "=== TwitchStreamFetcher Settings ===";
     qDebug() << "Settings file:" << m_settings->fileName();
     qDebug() << "AppDataLocation:" << dataPath;
     
     // Load cached tokens
     loadClientIntegrity();
     loadGraphQLToken();
            
        if (!m_graphQLToken.isEmpty()) {
            emit graphQLTokenChanged();
            requestUserInfo();
    }
 }
 
 TwitchStreamFetcher::~TwitchStreamFetcher()
 {
 }
 
 void TwitchStreamFetcher::setAuthManager(TwitchAuthManager *authManager)
 {
     m_authManager = authManager;
     qDebug() << "TwitchStreamFetcher: Auth manager set";
 }
 
 // ========================================
 // GraphQL Token Management
 // ========================================
 
 void TwitchStreamFetcher::setGraphQLToken(const QString &token)
 {
     QString trimmed = token.trimmed();
     
     if (trimmed.isEmpty()) {
         qWarning() << "Cannot set empty GraphQL token";
         return;
     }
     
     m_graphQLToken = trimmed;
     saveGraphQLToken();
     
     qDebug() << "✅ GraphQL token set (length:" << m_graphQLToken.length() << ")";
     emit graphQLTokenChanged();
 }
 
void TwitchStreamFetcher::clearGraphQLToken()
{
    m_graphQLToken.clear();
    m_settings->remove("auth/graphql_token");
    m_settings->sync();
    
    // NEU: Clear user info
    m_currentUserId.clear();
    m_currentUserLogin.clear();
    m_currentUserDisplayName.clear();
    m_currentUserProfileImage.clear();
    
    // Reset debug info
    m_debugShowAds = "N/A";
    m_debugHideAds = "N/A";
    m_debugPrivileged = "N/A";
    m_debugRole = "N/A";
    m_debugSubscriber = "N/A";
    m_debugTurbo = "N/A";
    m_debugAdblock = "N/A";
    
    qDebug() << "GraphQL token and user info cleared";
    emit graphQLTokenChanged();
    emit currentUserChanged();  // NEU
    emit debugInfoChanged();
}

 void TwitchStreamFetcher::validateGraphQLToken() {
    if (m_graphQLToken.isEmpty()) {
        emit tokenValidationFailed("No token to validate");
        return;
    }
    m_isValidatingToken = true;
    emit validatingTokenChanged();
    requestUserInfo();
}
 
 void TwitchStreamFetcher::loadGraphQLToken()
 {
     qDebug() << "=== Loading GraphQL token ===";
     qDebug() << "Settings file:" << m_settings->fileName();
     qDebug() << "All keys:" << m_settings->allKeys();
     
     m_graphQLToken = m_settings->value("auth/graphql_token").toString();
     
     if (!m_graphQLToken.isEmpty()) {
         qDebug() << "✅ Loaded GraphQL token (length:" << m_graphQLToken.length() << ")";
     } else {
         qDebug() << "❌ No GraphQL token in settings";
     }
 }
 
 void TwitchStreamFetcher::saveGraphQLToken()
 {
     qDebug() << "=== Saving GraphQL token ===";
     qDebug() << "Settings file:" << m_settings->fileName();
     qDebug() << "Token length:" << m_graphQLToken.length();
     
     m_settings->setValue("auth/graphql_token", m_graphQLToken);
     m_settings->sync();
     
     qDebug() << "Sync status:" << m_settings->status();
     qDebug() << "All keys after save:" << m_settings->allKeys();
     qDebug() << "✅ GraphQL token saved";
 }
 
 // ========================================
 // Stream Fetching
 // ========================================
 
 void TwitchStreamFetcher::fetchStreamUrl(const QString &channelName, const QString &quality)
 {
     qDebug() << "Fetching stream URL for channel:" << channelName << "quality:" << quality;
     
     m_currentChannel = channelName;
     m_requestedQuality = quality;
     m_isValidatingToken = false;
     
     emit statusUpdate("Connecting to Twitch...");
     
     // Try without client-integrity first
     requestPlaybackToken(channelName, false);
 }
 
 void TwitchStreamFetcher::requestPlaybackToken(const QString &channelName, bool withIntegrity)
 {
    QUrl url(TWITCH_GQL_URL);
    QNetworkRequest request(url);
     request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
     
     // Always use public Client-ID for GraphQL
     request.setRawHeader("Client-ID", Config::TWITCH_PUBLIC_CLIENT_ID.toUtf8());
     
     // Use GraphQL token if available, otherwise try OAuth token
     if (!m_graphQLToken.isEmpty()) {
         // Use GraphQL auth-token
         request.setRawHeader("Authorization", QString("OAuth %1").arg(m_graphQLToken).toUtf8());
         qDebug() << "✅ Using GraphQL auth-token";
     } else if (m_authManager && m_authManager->isAuthenticated()) {
         // Fallback to OAuth token (probably won't work for ad-free, but try anyway)
         request.setRawHeader("Authorization", QString("OAuth %1").arg(m_authManager->accessToken()).toUtf8());
         qDebug() << "⚠️  Using OAuth token (may not provide ad-free streams)";
     } else {
         qDebug() << "Using anonymous request (will have ads)";
     }
     
     // Add Client-Integrity token if available and requested
     if (withIntegrity && !m_clientIntegrityToken.isEmpty()) {
         request.setRawHeader("Client-Integrity", m_clientIntegrityToken.toUtf8());
         qDebug() << "✅ Using Client-Integrity token";
     }
     
     // Add X-Device-ID if we have one
     if (!m_deviceId.isEmpty()) {
         request.setRawHeader("X-Device-Id", m_deviceId.toUtf8());
     }
     
     // Build GraphQL query
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
     qDebug() << "  With Integrity:" << withIntegrity;
     qDebug() << "  Has GraphQL Token:" << !m_graphQLToken.isEmpty();
     qDebug() << "  Is Validation:" << m_isValidatingToken;
     
     QNetworkReply *reply = m_networkManager->post(request, data);
     
     if (m_isValidatingToken) {
         connect(reply, &QNetworkReply::finished, this, &TwitchStreamFetcher::onTokenValidationReceived);
     } else {
     connect(reply, &QNetworkReply::finished, this, &TwitchStreamFetcher::onPlaybackTokenReceived);
 }
 }
 
 void TwitchStreamFetcher::onTokenValidationReceived()
 {
     QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
     if (!reply) return;
     
     reply->deleteLater();
     
     m_isValidatingToken = false;
     emit validatingTokenChanged();
     
     // Check for network errors
     if (reply->error() != QNetworkReply::NoError) {
         int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
         qWarning() << "Token validation failed:" << reply->errorString();
         qWarning() << "HTTP status code:" << statusCode;
         
         if (statusCode == 401 || statusCode == 403) {
             emit tokenValidationFailed("Token is invalid or expired (HTTP " + QString::number(statusCode) + ")");
         } else {
             emit tokenValidationFailed("Network error: " + reply->errorString());
         }
         return;
     }
     
     QByteArray responseData = reply->readAll();
     QJsonDocument doc = QJsonDocument::fromJson(responseData);
     
     if (doc.isNull() || !doc.isObject()) {
         emit tokenValidationFailed("Invalid response from Twitch");
         return;
     }
     
     QJsonObject root = doc.object();
     
     // Check for errors
     if (root.contains("errors")) {
         QJsonArray errors = root["errors"].toArray();
         if (!errors.isEmpty()) {
             QString errorMsg = errors[0].toObject()["message"].toString();
             qWarning() << "Twitch API error:" << errorMsg;
             emit tokenValidationFailed("Twitch error: " + errorMsg);
             return;
         }
     }
     
     // Extract token and parse debug info
     QJsonObject data = root["data"].toObject();
     QJsonObject streamPlaybackAccessToken = data["streamPlaybackAccessToken"].toObject();
     
     if (streamPlaybackAccessToken.isEmpty()) {
         emit tokenValidationFailed("Test channel not available (try again later)");
         return;
     }
     
     QString token = streamPlaybackAccessToken["value"].toString();
     
     if (token.isEmpty()) {
         emit tokenValidationFailed("Failed to get test token");
         return;
     }
     
     // Parse debug info to show ad status
     parseDebugInfo(token);
     
     // Build success message
     QString message = "✅ Token valid!\n\n";
     message += "Ad Status:\n";
     message += "• Show Ads: " + m_debugShowAds + "\n";
     message += "• Hide Ads: " + m_debugHideAds + "\n";
     
     if (m_debugShowAds == "false" || m_debugHideAds == "true") {
         message += "\n🎉 Ad-free playback enabled!";
     } else {
         message += "\n⚠️  Ads may still appear (Turbo/Sub required)";
     }
     
     qDebug() << "✅ Token validation successful";
     emit tokenValidationSuccess(message);
 }
 
 void TwitchStreamFetcher::onPlaybackTokenReceived()
 {
     QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
     if (!reply) return;
     
     reply->deleteLater();
     
     // Check for network errors
     if (reply->error() != QNetworkReply::NoError) {
         int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
         qWarning() << "Network error:" << reply->errorString();
         qWarning() << "HTTP status code:" << statusCode;
         
         // Read response body for more details
         QByteArray errorBody = reply->readAll();
         if (!errorBody.isEmpty()) {
             qWarning() << "Error response body:" << errorBody;
         }
         
         // If 401/403 and we don't have client-integrity yet, try getting it
         if ((statusCode == 401 || statusCode == 403) && 
             m_clientIntegrityToken.isEmpty() &&
             !m_graphQLToken.isEmpty()) {
             
             qDebug() << "❌ Authentication failed, trying to get Client-Integrity token...";
             emit statusUpdate("Getting integrity token...");
             requestClientIntegrity();
             return;
         }
         
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
             qWarning() << "Twitch API error:" << errorMsg;
             
             // Check if it's an integrity error
             if (errorMsg.contains("integrity", Qt::CaseInsensitive) && 
                 m_clientIntegrityToken.isEmpty() &&
                 !m_graphQLToken.isEmpty()) {
                 
                 qDebug() << "❌ Integrity required, fetching token...";
                 emit statusUpdate("Getting integrity token...");
                 requestClientIntegrity();
                 return;
             }
             
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
     
     // Parse debug info from token
     parseDebugInfo(token);
     
     qDebug() << "✅ Got token and signature, fetching playlist...";
     emit statusUpdate("Getting stream playlist...");
     
     requestPlaylist(token, signature, m_currentChannel);
 }
 
 
 void TwitchStreamFetcher::requestClientIntegrity()
 {
     qDebug() << "Requesting Client-Integrity token from /integrity endpoint...";
     
     // Make sure we have GraphQL token
     if (m_graphQLToken.isEmpty()) {
         qWarning() << "Cannot get client-integrity without GraphQL token";
         emit error("GraphQL token required for this stream");
         return;
     }
     
     // Get or create device ID
     QString deviceId = getOrCreateDeviceId();
     
     QUrl url(TWITCH_INTEGRITY_URL);
     QNetworkRequest request(url);
     
     request.setRawHeader("Client-ID", Config::TWITCH_PUBLIC_CLIENT_ID.toUtf8());
     request.setRawHeader("Authorization", QString("OAuth %1").arg(m_graphQLToken).toUtf8());
     request.setRawHeader("X-Device-Id", deviceId.toUtf8());
     
     // Optional but recommended headers
     request.setRawHeader("Content-Type", "application/json");
     request.setRawHeader("User-Agent", 
         "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");
     
     qDebug() << "Device-ID:" << deviceId;
     
     // Empty POST body
     QByteArray emptyBody;
     
     QNetworkReply *reply = m_networkManager->post(request, emptyBody);
     connect(reply, &QNetworkReply::finished, this, &TwitchStreamFetcher::onClientIntegrityReceived);
 }
 
 void TwitchStreamFetcher::onClientIntegrityReceived()
 {
     QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
     if (!reply) return;
     
     reply->deleteLater();
     
     if (reply->error() != QNetworkReply::NoError) {
         qWarning() << "Failed to get client-integrity token:" << reply->errorString();
         QByteArray errorBody = reply->readAll();
         if (!errorBody.isEmpty()) {
             qWarning() << "Error response:" << errorBody;
         }
         emit error("Failed to get integrity token: " + reply->errorString());
         return;
     }
     
     QByteArray responseData = reply->readAll();
     qDebug() << "Client-Integrity response received, size:" << responseData.size();
     
     QJsonDocument doc = QJsonDocument::fromJson(responseData);
     if (doc.isNull() || !doc.isObject()) {
         emit error("Invalid client-integrity response");
         return;
     }
     
     QJsonObject obj = doc.object();
     
     m_clientIntegrityToken = obj["token"].toString();

     // Parse expiration - Twitch sends "expires_in" (seconds from now)
     if (obj.contains("expires_in")) {
         int expiresIn = obj["expires_in"].toInt();
         m_clientIntegrityExpiration = QDateTime::currentDateTime().addSecs(expiresIn);
         qDebug() << "Token expires in" << expiresIn << "seconds";
     } else {
         // Default: 16 hours
         m_clientIntegrityExpiration = QDateTime::currentDateTime().addSecs(16 * 3600);
         qDebug() << "No expires_in, using default 16h";
     }
     
     if (m_clientIntegrityToken.isEmpty()) {
         emit error("Failed to get integrity token from response");
         return;
     }
     
     qDebug() << "✅ Got Client-Integrity token!";
     qDebug() << "Token starts with:" << m_clientIntegrityToken.left(20) << "...";
     qDebug() << "Expires at:" << m_clientIntegrityExpiration;
     
     // Save to cache
     saveClientIntegrity();
     
     // Now retry the playback token request with integrity
     emit statusUpdate("Retrying with integrity token...");
     requestPlaybackToken(m_currentChannel, true);
 }
 
void TwitchStreamFetcher::parseDebugInfo(const QString &tokenValue)
{
    qDebug() << "=== Parsing Token Value ===";
    qDebug() << "Raw token value:" << tokenValue;
    qDebug() << "===========================";
    
    // Token value is a JSON string, parse it
    QJsonDocument doc = QJsonDocument::fromJson(tokenValue.toUtf8());
    if (doc.isNull() || !doc.isObject()) {
        qDebug() << "Could not parse token for debug info";
        return;
    }
    
    QJsonObject obj = doc.object();
    
    // Log all fields for debugging
    qDebug() << "=== All Token Fields ===";
    for (const QString &key : obj.keys()) {
        QJsonValue value = obj[key];
        if (value.isBool()) {
            qDebug() << key << ":" << value.toBool();
        } else if (value.isString()) {
            qDebug() << key << ":" << value.toString();
        } else if (value.isDouble()) {
            qDebug() << key << ":" << value.toDouble();
        } else {
            qDebug() << key << ":" << value;
        }
    }
    qDebug() << "========================";
    
    // Extract debug fields with better null handling
    m_debugShowAds = obj.contains("show_ads") ? (obj["show_ads"].toBool() ? "true" : "false") : "N/A";
    m_debugHideAds = obj.contains("hide_ads") ? (obj["hide_ads"].toBool() ? "true" : "false") : "N/A";
    m_debugPrivileged = obj.contains("privileged") ? (obj["privileged"].toBool() ? "true" : "false") : "N/A";
    m_debugRole = obj.contains("role") ? obj["role"].toString() : "N/A";
    m_debugSubscriber = obj.contains("subscriber") ? (obj["subscriber"].toBool() ? "true" : "false") : "N/A";
    m_debugTurbo = obj.contains("turbo") ? (obj["turbo"].toBool() ? "true" : "false") : "N/A";
    m_debugAdblock = obj.contains("adblock") ? (obj["adblock"].toBool() ? "true" : "false") : "N/A";
    
    qDebug() << "=== Extracted Debug Info ===";
    qDebug() << "Show Ads:" << m_debugShowAds;
    qDebug() << "Hide Ads:" << m_debugHideAds;
    qDebug() << "Privileged:" << m_debugPrivileged;
    qDebug() << "Role:" << m_debugRole;
    qDebug() << "Subscriber:" << m_debugSubscriber;
    qDebug() << "Turbo:" << m_debugTurbo;
    qDebug() << "Adblock:" << m_debugAdblock;
    qDebug() << "============================";
    
    emit debugInfoChanged();
}
 
 void TwitchStreamFetcher::requestPlaylist(const QString &token, const QString &signature, const QString &channelName)
 {
     // Build usher URL
     QString usherUrl = TWITCH_USHER_URL.arg(channelName);
     
     QUrlQuery query;
     query.addQueryItem("client_id", Config::TWITCH_PUBLIC_CLIENT_ID);
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
    emit statusUpdate("Stream ready!");
    emit streamUrlReady(streamUrl, m_currentChannel);
 }

QString TwitchStreamFetcher::parseM3U8Playlist(const QString &m3u8Content, const QString &quality)
{
    QStringList lines = m3u8Content.split('\n');
    
    // Clear previous cache
    m_qualityUrls.clear();
    m_availableQualities.clear();
    
    // Parse ALL qualities from playlist
    for (int i = 0; i < lines.size(); i++) {
        QString line = lines[i].trimmed();
        
        if (line.startsWith("#EXT-X-STREAM-INF")) {
            // Extract quality name from line
            QString qualityName = "unknown";
            
            // Try to extract resolution
            if (line.contains("RESOLUTION=1920x1080")) {
                qualityName = "1080p (Source)";
            } else if (line.contains("RESOLUTION=1280x720")) {
                qualityName = "720p (High)";
            } else if (line.contains("RESOLUTION=852x480") || line.contains("RESOLUTION=640x480")) {
                qualityName = "480p (Medium)";
            } else if (line.contains("RESOLUTION=640x360")) {
                qualityName = "360p (Low)";
            } else if (line.contains("RESOLUTION=284x160") || line.contains("RESOLUTION=160x")) {
                qualityName = "160p (Mobile)";
            } else if (line.contains("audio_only")) {
                qualityName = "Audio Only";
            }
            
            // Next line should be the URL
            if (i + 1 < lines.size()) {
                QString nextLine = lines[i + 1].trimmed();
                if (nextLine.startsWith("http")) {
                    m_qualityUrls[qualityName] = nextLine;
                    m_availableQualities.append(qualityName);
                    
                    qDebug() << "  Found quality:" << qualityName;
                }
            }
        }
    }
    
    // Emit signal that qualities are available
    if (!m_availableQualities.isEmpty()) {
        qDebug() << "✅ Cached" << m_availableQualities.size() << "quality options";
        emit availableQualitiesChanged(m_availableQualities);
    }
    
    // Quality mapping for "best", "source", etc.
    QMap<QString, QString> qualityMap;
    qualityMap["best"] = "1080p";
    qualityMap["source"] = "1080p";
    qualityMap["high"] = "720p";
    qualityMap["medium"] = "480p";
    qualityMap["low"] = "360p";
    qualityMap["mobile"] = "160p";
    
    QString targetResolution = qualityMap.value(quality.toLower(), "1080p");
    
    qDebug() << "Looking for quality:" << quality << "-> resolution:" << targetResolution;
    
    // Try to find exact match
    for (const QString &qualName : m_availableQualities) {
        if (qualName.contains(targetResolution, Qt::CaseInsensitive)) {
            return m_qualityUrls[qualName];
        }
    }
    
    // If not found, return the first (best) quality
    if (!m_availableQualities.isEmpty()) {
        qDebug() << "Using first available quality:" << m_availableQualities.first();
        return m_qualityUrls[m_availableQualities.first()];
    }
    
    return QString();
}

QString TwitchStreamFetcher::getQualityUrl(const QString &quality) const
{
    // Try direct match first
    if (m_qualityUrls.contains(quality)) {
        return m_qualityUrls[quality];
    }
    
    // Try fuzzy match (e.g. "720p" matches "720p (High)")
    for (const QString &key : m_qualityUrls.keys()) {
        if (key.contains(quality, Qt::CaseInsensitive)) {
            return m_qualityUrls[key];
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

 // ========================================
// User Info Methods - TWO STEP APPROACH
// ========================================

void TwitchStreamFetcher::fetchCurrentUser()
{
    if (m_graphQLToken.isEmpty()) {
        qWarning() << "Cannot fetch user info without GraphQL token";
        return;
    }
    
    qDebug() << "Fetching current user info (step 1: get user ID)...";
    requestUserInfo();
}

void TwitchStreamFetcher::requestUserInfo()
{
    QUrl url(TWITCH_GQL_URL);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    
    // Use public Client-ID and GraphQL token
    request.setRawHeader("Client-ID", Config::TWITCH_PUBLIC_CLIENT_ID.toUtf8());
    request.setRawHeader("Authorization", QString("OAuth %1").arg(m_graphQLToken).toUtf8());
    
    // Build GraphQL query for UserMenuCurrentUser (just to get ID)
    QJsonObject persistedQuery;
    persistedQuery["version"] = 1;
    persistedQuery["sha256Hash"] = PERSISTED_QUERY_HASH_USER;
    
    QJsonObject extensions;
    extensions["persistedQuery"] = persistedQuery;
    
    QJsonObject payload;
    payload["operationName"] = "UserMenuCurrentUser";
    payload["variables"] = QJsonObject();
    payload["extensions"] = extensions;
    
    QJsonDocument doc(payload);
    QByteArray data = doc.toJson(QJsonDocument::Compact);
    
    qDebug() << "Sending UserMenuCurrentUser query (step 1: get ID only)...";
    
    QNetworkReply *reply = m_networkManager->post(request, data);
    
    // Store that this is first step
    reply->setProperty("isFirstStep", true);
    
    connect(reply, &QNetworkReply::finished, this, &TwitchStreamFetcher::onUserInfoReceived);
}

void TwitchStreamFetcher::requestUserDetails(const QString &userId)
{
    // Use Twitch Helix REST API instead of GetUserByConnection
    QUrl url(QString("https://api.twitch.tv/helix/users?id=%1").arg(userId));
    QNetworkRequest request(url);
    
    // Use public Client-ID and GraphQL token
    request.setRawHeader("Client-ID", Config::TWITCH_PUBLIC_CLIENT_ID.toUtf8());
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_graphQLToken).toUtf8());
    
    qDebug() << "Fetching user details via Helix API (step 2) for user ID:" << userId;
    
    QNetworkReply *reply = m_networkManager->get(request);
    
    // Mark as second step
    reply->setProperty("isFirstStep", false);
    
    connect(reply, &QNetworkReply::finished, this, &TwitchStreamFetcher::onUserInfoReceived);
}

void TwitchStreamFetcher::onUserInfoReceived()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    
    bool isFirstStep = reply->property("isFirstStep").toBool();
    
    reply->deleteLater();
    
    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Failed to fetch user info (step" << (isFirstStep ? "1" : "2") << "):" << reply->errorString();
        
        if (m_isValidatingToken) {
            m_isValidatingToken = false;
            emit validatingTokenChanged();
            emit tokenValidationFailed("Failed to validate token: " + reply->errorString());
        }
        return;
    }
    
    QByteArray responseData = reply->readAll();
    qDebug() << "=== User Info Response (step" << (isFirstStep ? "1" : "2") << ") ===";
    qDebug() << responseData;
    qDebug() << "====================================";
    
    QJsonDocument doc = QJsonDocument::fromJson(responseData);
    
    if (doc.isNull() || !doc.isObject()) {
        if (m_isValidatingToken) {
            m_isValidatingToken = false;
            emit validatingTokenChanged();
            emit tokenValidationFailed("Invalid response from Twitch");
        }
        return;
    }
    
    QJsonObject root = doc.object();
    
    // Check for errors
    if (root.contains("errors")) {
        QJsonArray errors = root["errors"].toArray();
        if (!errors.isEmpty()) {
            QString errorMsg = errors[0].toObject()["message"].toString();
            qWarning() << "Twitch API error:" << errorMsg;
            
            if (m_isValidatingToken) {
                m_isValidatingToken = false;
                emit validatingTokenChanged();
                emit tokenValidationFailed("Twitch error: " + errorMsg);
            }
            return;
        }
    }
    
    QJsonObject data = root["data"].toObject();
    
    if (isFirstStep) {
        // Step 1: Extract user ID from UserMenuCurrentUser
        QJsonObject currentUser = data["currentUser"].toObject();
        
        if (currentUser.isEmpty() || currentUser["id"].toString().isEmpty()) {
            if (m_isValidatingToken) {
                m_isValidatingToken = false;
                emit validatingTokenChanged();
                emit tokenValidationFailed("Token is invalid or user not found");
            }
            return;
        }
        
        QString userId = currentUser["id"].toString();
        qDebug() << "✅ Got user ID:" << userId << "- fetching details...";
        
        // Store ID temporarily
        m_currentUserId = userId;
        
        // Also get profile image from this response (if available)
        if (currentUser.contains("profileImageURL")) {
            m_currentUserProfileImage = currentUser["profileImageURL"].toString();
            qDebug() << "  Also got profile image URL from step 1";
        }
        
        // Now fetch full details
        requestUserDetails(userId);
        
    } else {
        // Step 2: Extract full details from Helix API
        // Helix format: { "data": [ { "id": "...", "login": "...", "display_name": "...", "profile_image_url": "..." } ] }
        QJsonArray users = data["data"].toArray();
        
        if (users.isEmpty()) {
            qWarning() << "User details not found in step 2 response";
            
            if (m_isValidatingToken) {
                m_isValidatingToken = false;
                emit validatingTokenChanged();
                emit tokenValidationFailed("Failed to get user details");
            }
            return;
        }
        
        QJsonObject user = users[0].toObject();
        
        // Store user info from Helix API
        // Note: Keep m_currentUserId from step 1 (it's already set)
        m_currentUserLogin = user["login"].toString();
        m_currentUserDisplayName = user["display_name"].toString();
        
        // Use profile_image_url if we don't have profileImageURL from step 1
        if (m_currentUserProfileImage.isEmpty() && user.contains("profile_image_url")) {
            m_currentUserProfileImage = user["profile_image_url"].toString();
        }
        
        qDebug() << "✅ User details received from Helix API:";
        qDebug() << "  ID:" << m_currentUserId;
        qDebug() << "  Login:" << m_currentUserLogin;
        qDebug() << "  Display Name:" << m_currentUserDisplayName;
        qDebug() << "  Profile Image:" << m_currentUserProfileImage;
        
        emit currentUserChanged();
        
        if (m_isValidatingToken) {
            m_isValidatingToken = false;
            emit validatingTokenChanged();
            
            QString message = "✅ Token valid!\n\n";
            message += "Logged in as: " + m_currentUserDisplayName;
            if (!m_currentUserLogin.isEmpty()) {
                message += " (@" + m_currentUserLogin + ")";
            }
            message += "\nUser ID: " + m_currentUserId;
            
            emit tokenValidationSuccess(message);
        }
    }
}
 
 // ========================================
 // Client-Integrity Token Management
 // ========================================
 
 void TwitchStreamFetcher::loadClientIntegrity()
 {
     m_clientIntegrityToken = m_settings->value("integrity/token").toString();
     m_clientIntegrityExpiration = m_settings->value("integrity/expiration").toDateTime();
     m_deviceId = m_settings->value("integrity/device_id").toString();
     
     if (!m_clientIntegrityToken.isEmpty()) {
         qDebug() << "Loaded cached Client-Integrity token";
         qDebug() << "Expires at:" << m_clientIntegrityExpiration;
         
         // Check if expired
         if (!isClientIntegrityValid()) {
             qDebug() << "Cached token expired, will request new one";
             m_clientIntegrityToken.clear();
         }
     }
 }
 
 void TwitchStreamFetcher::saveClientIntegrity()
 {
     m_settings->setValue("integrity/token", m_clientIntegrityToken);
     m_settings->setValue("integrity/expiration", m_clientIntegrityExpiration);
     m_settings->setValue("integrity/device_id", m_deviceId);
     m_settings->sync();
     
     qDebug() << "Saved Client-Integrity token to cache";
 }
 
 bool TwitchStreamFetcher::isClientIntegrityValid() const
 {
     if (m_clientIntegrityToken.isEmpty()) {
         return false;
     }
     
     // Check expiration
     if (!m_clientIntegrityExpiration.isValid()) {
         return false;
     }
     
     // Add 5 minute buffer
     return m_clientIntegrityExpiration.addSecs(-300) > QDateTime::currentDateTime();
 }
 
 QString TwitchStreamFetcher::getOrCreateDeviceId()
 {
     if (m_deviceId.isEmpty()) {
         // Generate new UUID
         m_deviceId = QUuid::createUuid().toString(QUuid::WithoutBraces);
         qDebug() << "Generated new Device-ID:" << m_deviceId;
     }
     
     return m_deviceId;
 }