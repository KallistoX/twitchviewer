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

 #include "twitchauthmanager.h"
 #include "config.h"
 #include <QNetworkRequest>
 #include <QUrlQuery>
 #include <QJsonDocument>
 #include <QJsonObject>
 #include <QJsonArray>
 #include <QDebug>
 #include <QStandardPaths>
 #include <QDir>
 
 // Twitch OAuth Device Flow endpoints
 const QString TwitchAuthManager::TWITCH_DEVICE_URL = "https://id.twitch.tv/oauth2/device";
 const QString TwitchAuthManager::TWITCH_TOKEN_URL = "https://id.twitch.tv/oauth2/token";
 const QString TwitchAuthManager::TWITCH_VALIDATE_URL = "https://id.twitch.tv/oauth2/validate";
 
 const QString TwitchAuthManager::OAUTH_SCOPES = "user:read:email user:read:follows";
 
 TwitchAuthManager::TwitchAuthManager(QObject *parent)
     : QObject(parent)
     , m_networkManager(new QNetworkAccessManager(this))
     , m_pollTimer(new QTimer(this))
     , m_expiresIn(0)
     , m_interval(5)
     , m_isPolling(false)
 {
     // CRITICAL FIX: Use AppDataLocation for Ubuntu Touch confinement
     QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
     
     // Ensure directory exists
     QDir().mkpath(dataPath);
     
     QString settingsFile = dataPath + "/twitchviewer.conf";
     m_settings = new QSettings(settingsFile, QSettings::NativeFormat, this);
     
     qDebug() << "=== TwitchAuthManager Settings ===";
     qDebug() << "Settings file:" << m_settings->fileName();
     qDebug() << "AppDataLocation:" << dataPath;
     
     connect(m_pollTimer, &QTimer::timeout, this, &TwitchAuthManager::pollForToken);
     
     // Load saved tokens on startup
     loadTokens();
     
     // If we have a token, validate it and emit auth state
     if (!m_accessToken.isEmpty()) {
         qDebug() << "Found saved access token, validating...";
         validateToken();
     } else {
         qDebug() << "No saved access token found";
         emit authenticationChanged(false);
     }
 }
 
 TwitchAuthManager::~TwitchAuthManager()
 {
     stopPolling();
 }
 
 void TwitchAuthManager::startDeviceAuth()
 {
     qDebug() << "Starting OAuth Device Flow...";
     emit statusMessage("Requesting device code...");
     
     QUrl url(TWITCH_DEVICE_URL);
     QNetworkRequest request(url);
     request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
     
     QUrlQuery params;
     params.addQueryItem("client_id", Config::TWITCH_CLIENT_ID);
     params.addQueryItem("scopes", OAUTH_SCOPES);
     
     QByteArray data = params.toString(QUrl::FullyEncoded).toUtf8();
     
     QNetworkReply *reply = m_networkManager->post(request, data);
     connect(reply, &QNetworkReply::finished, this, &TwitchAuthManager::onDeviceCodeReceived);
 }
 
 void TwitchAuthManager::onDeviceCodeReceived()
 {
     QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
     if (!reply) return;
     
     reply->deleteLater();
     
     if (reply->error() != QNetworkReply::NoError) {
         qWarning() << "Device code request failed:" << reply->errorString();
         emit authenticationFailed("Network error: " + reply->errorString());
         return;
     }
     
     QByteArray responseData = reply->readAll();
     QJsonDocument doc = QJsonDocument::fromJson(responseData);
     
     if (doc.isNull() || !doc.isObject()) {
         emit authenticationFailed("Invalid response from Twitch");
         return;
     }
     
     QJsonObject obj = doc.object();
     
     // Extract device flow parameters
     m_deviceCode = obj["device_code"].toString();
     m_userCode = obj["user_code"].toString();
     m_verificationUrl = obj["verification_uri"].toString();
     m_expiresIn = obj["expires_in"].toInt();
     m_interval = obj["interval"].toInt();
     
     if (m_deviceCode.isEmpty() || m_userCode.isEmpty()) {
         emit authenticationFailed("Failed to get device code");
         return;
     }
     
     qDebug() << "Device code received:";
     qDebug() << "  User Code:" << m_userCode;
     qDebug() << "  Verification URL:" << m_verificationUrl;
     qDebug() << "  Expires in:" << m_expiresIn << "seconds";
     qDebug() << "  Poll interval:" << m_interval << "seconds";
     
     emit userCodeChanged(m_userCode);
     emit verificationUrlChanged(m_verificationUrl);
     emit statusMessage("Waiting for authorization...");
     
     // Start polling for token
     startPolling();
 }
 
 void TwitchAuthManager::startPolling()
 {
     m_isPolling = true;
     emit pollingChanged(true);
     
     // Start polling with the interval from Twitch
     m_pollTimer->start(m_interval * 1000);
     
     // Do first poll immediately
     pollForToken();
 }
 
 void TwitchAuthManager::stopPolling()
 {
     m_isPolling = false;
     emit pollingChanged(false);
     m_pollTimer->stop();
 }
 
 void TwitchAuthManager::pollForToken()
 {
     qDebug() << "Polling for token...";
     
     QUrl url(TWITCH_TOKEN_URL);
     QNetworkRequest request(url);
     request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
     
     QUrlQuery params;
     params.addQueryItem("client_id", Config::TWITCH_CLIENT_ID);
     params.addQueryItem("device_code", m_deviceCode);
     params.addQueryItem("grant_type", "urn:ietf:params:oauth:grant-type:device_code");
     
     QByteArray data = params.toString(QUrl::FullyEncoded).toUtf8();
     
     QNetworkReply *reply = m_networkManager->post(request, data);
     connect(reply, &QNetworkReply::finished, this, &TwitchAuthManager::onTokenReceived);
 }
 
 void TwitchAuthManager::onTokenReceived()
 {
     QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
     if (!reply) return;
     
     reply->deleteLater();
     
     QByteArray responseData = reply->readAll();
    qDebug() << "Token response received:" << responseData;
    
     QJsonDocument doc = QJsonDocument::fromJson(responseData);
     
     if (doc.isNull() || !doc.isObject()) {
         qWarning() << "Invalid JSON response";
         return;
     }
     
     QJsonObject obj = doc.object();
    qDebug() << "Parsed JSON object keys:" << obj.keys();
     
     // Check for errors
     if (obj.contains("status") && obj["status"].toInt() == 400) {
         QString error = obj["message"].toString();
         
         if (error == "authorization_pending") {
             // User hasn't authorized yet - keep polling
             qDebug() << "Authorization pending...";
             return;
         } else if (error == "slow_down") {
             // We're polling too fast - increase interval
             qDebug() << "Slowing down polling...";
             m_interval += 5;
             m_pollTimer->setInterval(m_interval * 1000);
             return;
         } else if (error == "expired_token") {
             // Device code expired
             stopPolling();
             emit authenticationFailed("Device code expired. Please try again.");
             return;
         } else {
             stopPolling();
             emit authenticationFailed("Authorization failed: " + error);
             return;
         }
     }
     
     // Success! We have the token
     m_accessToken = obj["access_token"].toString();
     m_refreshToken = obj["refresh_token"].toString();
     
     if (m_accessToken.isEmpty()) {
         stopPolling();
         emit authenticationFailed("Failed to get access token");
         return;
     }
     
     qDebug() << "✅ Authentication successful!";
     qDebug() << "Access token received (length:" << m_accessToken.length() << ")";
     qDebug() << "Refresh token received (length:" << m_refreshToken.length() << ")";
     
     stopPolling();
     saveTokens();
     
     emit authenticationChanged(true);
     emit authenticationSucceeded();
     emit statusMessage("Successfully authenticated!");
 }
 
 void TwitchAuthManager::validateToken()
 {
     qDebug() << "Validating access token...";
     
     QUrl url(TWITCH_VALIDATE_URL);
     QNetworkRequest request(url);
     request.setRawHeader("Authorization", QString("OAuth %1").arg(m_accessToken).toUtf8());
     
     QNetworkReply *reply = m_networkManager->get(request);
     connect(reply, &QNetworkReply::finished, this, &TwitchAuthManager::onTokenValidated);
 }
 
 void TwitchAuthManager::onTokenValidated()
 {
     QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
     if (!reply) return;
     
     reply->deleteLater();
     
     if (reply->error() != QNetworkReply::NoError) {
         qWarning() << "Token validation failed:" << reply->errorString();
         
         // Check if we have a refresh token to try
         if (!m_refreshToken.isEmpty()) {
             qDebug() << "Access token expired, attempting to refresh...";
             refreshAccessToken();
             return;
         }
         
         qDebug() << "No refresh token available, clearing tokens and logging out";
         clearTokens();
         emit authenticationChanged(false);
         return;
     }
     
     QByteArray responseData = reply->readAll();
     QJsonDocument doc = QJsonDocument::fromJson(responseData);
     
     if (doc.isNull() || !doc.isObject()) {
         qWarning() << "Invalid validation response";
         
         // Try refresh if available
         if (!m_refreshToken.isEmpty()) {
             qDebug() << "Invalid response, attempting to refresh token...";
             refreshAccessToken();
             return;
         }
         
         clearTokens();
         emit authenticationChanged(false);
         return;
     }
     
     QJsonObject obj = doc.object();
     QString clientId = obj["client_id"].toString();
     
     if (clientId != Config::TWITCH_CLIENT_ID) {
         qWarning() << "Token is for different client ID";
         
         // Try refresh if available
         if (!m_refreshToken.isEmpty()) {
             qDebug() << "Wrong client ID, attempting to refresh token...";
             refreshAccessToken();
             return;
         }
         
         clearTokens();
         emit authenticationChanged(false);
         return;
     }
     
     qDebug() << "✅ Token is valid!";
     emit authenticationChanged(true);
 }
 
 void TwitchAuthManager::refreshAccessToken()
 {
     if (m_refreshToken.isEmpty()) {
         qWarning() << "Cannot refresh token: no refresh token available";
         emit authenticationFailed("No refresh token available");
         clearTokens();
         emit authenticationChanged(false);
         return;
     }
     
     qDebug() << "Refreshing access token using refresh token...";
     emit statusMessage("Refreshing authentication...");
     
     QUrl url(TWITCH_TOKEN_URL);
     QNetworkRequest request(url);
     request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
     
     QUrlQuery params;
     params.addQueryItem("client_id", Config::TWITCH_CLIENT_ID);
     params.addQueryItem("grant_type", "refresh_token");
     params.addQueryItem("refresh_token", m_refreshToken);
     
     QByteArray data = params.toString(QUrl::FullyEncoded).toUtf8();
     
     QNetworkReply *reply = m_networkManager->post(request, data);
     connect(reply, &QNetworkReply::finished, this, &TwitchAuthManager::onRefreshTokenReceived);
 }
 
 void TwitchAuthManager::onRefreshTokenReceived()
 {
     QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
     if (!reply) return;
     
     reply->deleteLater();
     
     if (reply->error() != QNetworkReply::NoError) {
         qWarning() << "Token refresh failed:" << reply->errorString();
         QByteArray errorBody = reply->readAll();
         qWarning() << "Error response:" << errorBody;
         
         // Refresh token is also invalid/expired - user must re-authenticate
         qDebug() << "❌ Refresh token expired or invalid, user must log in again";
         emit authenticationFailed("Session expired. Please log in again.");
         clearTokens();
         emit authenticationChanged(false);
         return;
     }
     
     QByteArray responseData = reply->readAll();
     qDebug() << "Refresh token response received:" << responseData;
     
     QJsonDocument doc = QJsonDocument::fromJson(responseData);
     
     if (doc.isNull() || !doc.isObject()) {
         qWarning() << "Invalid refresh response";
         clearTokens();
         emit authenticationChanged(false);
         return;
     }
     
     QJsonObject obj = doc.object();
     
     // Update tokens
     QString newAccessToken = obj["access_token"].toString();
     QString newRefreshToken = obj["refresh_token"].toString();
     
     if (newAccessToken.isEmpty()) {
         qWarning() << "Failed to get new access token";
         clearTokens();
         emit authenticationChanged(false);
         return;
     }
     
     m_accessToken = newAccessToken;
     
     // Twitch may return a new refresh token, or keep the old one
     if (!newRefreshToken.isEmpty()) {
         m_refreshToken = newRefreshToken;
         qDebug() << "✅ Token refreshed successfully (new refresh token provided)";
     } else {
         qDebug() << "✅ Token refreshed successfully (refresh token reused)";
     }
     
     qDebug() << "New access token length:" << m_accessToken.length();
     
     saveTokens();
     
     emit authenticationChanged(true);
     emit tokenRefreshed();
     emit statusMessage("Authentication refreshed successfully!");
 }
 
 void TwitchAuthManager::logout()
 {
     qDebug() << "Logging out...";
     stopPolling();
     clearTokens();
     emit authenticationChanged(false);
     emit statusMessage("Logged out");
 }

 void TwitchAuthManager::saveTokens()
{
    qDebug() << "=== Saving OAuth tokens ===";
    qDebug() << "Settings file:" << m_settings->fileName();
     qDebug() << "Access token length:" << m_accessToken.length();
    qDebug() << "Refresh token length:" << m_refreshToken.length();
    
    m_settings->setValue("auth/access_token", m_accessToken);
    m_settings->setValue("auth/refresh_token", m_refreshToken);
    m_settings->sync();
    
    qDebug() << "Sync status:" << m_settings->status();
     qDebug() << "All keys after save:" << m_settings->allKeys();
    qDebug() << "✅ Tokens saved";
}
 
 void TwitchAuthManager::loadTokens()
 {
     qDebug() << "=== Loading OAuth tokens ===";
     qDebug() << "Settings file:" << m_settings->fileName();
     qDebug() << "All keys:" << m_settings->allKeys();
     
     m_accessToken = m_settings->value("auth/access_token").toString();
     m_refreshToken = m_settings->value("auth/refresh_token").toString();
     
     if (!m_accessToken.isEmpty()) {
        qDebug() << "✅ Loaded access token (length:" << m_accessToken.length() << ")";
         qDebug() << "  Token starts with:" << m_accessToken.left(10) << "...";
     } else {
        qDebug() << "❌ No access token found";
     }
     
     if (!m_refreshToken.isEmpty()) {
         qDebug() << "✅ Loaded refresh token (length:" << m_refreshToken.length() << ")";
     } else {
         qDebug() << "❌ No refresh token found";
     }
 }
 
 void TwitchAuthManager::clearTokens()
 {
     m_accessToken.clear();
     m_refreshToken.clear();
     m_settings->remove("auth/access_token");
     m_settings->remove("auth/refresh_token");
     m_settings->sync();
     qDebug() << "Tokens cleared";
 }