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
 #include "logging.h"
 #include <QNetworkRequest>
 #include <QUrlQuery>
 #include <QJsonDocument>
 #include <QJsonObject>
 #include <QJsonArray>
 #include <QStandardPaths>
 #include <QDir>
 #include "networkmanager.h"
 
 // Twitch OAuth Device Flow endpoints
 const QString TwitchAuthManager::TWITCH_DEVICE_URL = "https://id.twitch.tv/oauth2/device";
 const QString TwitchAuthManager::TWITCH_TOKEN_URL = "https://id.twitch.tv/oauth2/token";
 const QString TwitchAuthManager::TWITCH_VALIDATE_URL = "https://id.twitch.tv/oauth2/validate";
 
 const QString TwitchAuthManager::OAUTH_SCOPES = "user:read:email user:read:follows";
 
 TwitchAuthManager::TwitchAuthManager(QObject *parent)
     : QObject(parent)
     , m_netStatusManager(nullptr)
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
     
        
     connect(m_pollTimer, &QTimer::timeout, this, &TwitchAuthManager::pollForToken);
     
     // Load saved tokens on startup
     loadTokens();
     
     // If we have a token, validate it and emit auth state
     if (!m_accessToken.isEmpty()) {
         LOG_AUTH("Validating saved token");
         validateToken();
     } else {
          emit authenticationChanged(false);
     }
 }
 
 TwitchAuthManager::~TwitchAuthManager()
 {
     stopPolling();
 }
 
 void TwitchAuthManager::startDeviceAuth()
 {
     LOG_AUTH("Starting device auth flow");
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
         WARN_AUTH("Device code request failed:" << reply->errorString());
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
     
     QJsonDocument doc = QJsonDocument::fromJson(responseData);
     
     if (doc.isNull() || !doc.isObject()) {
         WARN_AUTH("Invalid JSON response");
         return;
     }
     
     QJsonObject obj = doc.object();
      
     // Check for errors
     if (obj.contains("status") && obj["status"].toInt() == 400) {
         QString error = obj["message"].toString();
         
         if (error == "authorization_pending") {
             // User hasn't authorized yet - keep polling
              return;
         } else if (error == "slow_down") {
             // We're polling too fast - increase interval
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
     
     LOG_AUTH("Authentication successful");
       
     stopPolling();
     saveTokens();
     
     emit authenticationChanged(true);
     emit authenticationSucceeded();
     emit statusMessage("Successfully authenticated!");
 }
 
 void TwitchAuthManager::validateToken()
 {
     LOG_AUTH("Validating token");
     
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
        WARN_AUTH("Token validation failed:" << reply->errorString());
        
        // ✅ FIX: Classify error BEFORE taking action!
        if (m_netStatusManager) {
            NetworkManager::ErrorType errorType = m_netStatusManager->classifyError(reply);
            QString errorMsg = m_netStatusManager->getErrorMessage(reply);
            
            if (errorType == NetworkManager::NetworkError) {
                // ✅ Network error - KEEP token, just notify user!
                m_netStatusManager->reportError(errorType);
                LOG_AUTH("Network error during validation - token preserved");
                emit authenticationFailed(errorMsg);
                return;  // <- IMPORTANT: Return here, don't clear tokens!
            }
            
            if (errorType == NetworkManager::ServerError) {
                // ✅ Server error - KEEP token, Twitch is down!
                LOG_AUTH("Server error during validation - token preserved");
                emit authenticationFailed(errorMsg);
                return;  // <- IMPORTANT: Return here, don't clear tokens!
            }
            
            // ✅ Only clear tokens on ACTUAL auth errors (401/403)
            if (errorType == NetworkManager::AuthError) {
                LOG_AUTH("Auth error - token invalid");
                // Try refresh if available
                if (!m_refreshToken.isEmpty()) {
                    LOG_AUTH("Attempting token refresh");
                    refreshAccessToken();
                    return;
                }
                
                // No refresh token - clear everything
                LOG_AUTH("No refresh token - clearing tokens");
                clearTokens();
                emit authenticationChanged(false);
                return;
            }
        } else {
            // Fallback if networkManager is not set (shouldn't happen)
            WARN_AUTH("NetworkManager not set");
            if (!m_refreshToken.isEmpty()) {
                refreshAccessToken();
                return;
            }
            clearTokens();
            emit authenticationChanged(false);
            return;
        }
    }
     
     LOG_AUTH("Token validated");
     m_netStatusManager->clearError();
     emit authenticationChanged(true);
 }
 
 void TwitchAuthManager::refreshAccessToken()
 {
     if (m_refreshToken.isEmpty()) {
         WARN_AUTH("No refresh token available");
         emit authenticationFailed("No refresh token available");
         clearTokens();
         emit authenticationChanged(false);
         return;
     }
     
     LOG_AUTH("Refreshing token");
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
 
void TwitchAuthManager::setNetworkManager(NetworkManager *networkManager)
{
    m_netStatusManager = networkManager;
    LOG_AUTH("NetworkManager set");
}

 void TwitchAuthManager::onRefreshTokenReceived()
 {
     QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
     if (!reply) return;
     
     reply->deleteLater();
     
     if (reply->error() != QNetworkReply::NoError) {
         WARN_AUTH("Token refresh failed:" << reply->errorString());
         QByteArray errorBody = reply->readAll();
          
         // Refresh token is also invalid/expired - user must re-authenticate
         LOG_AUTH("Refresh token expired - need login");
         emit authenticationFailed("Session expired. Please log in again.");
         clearTokens();
         emit authenticationChanged(false);
         return;
     }
     
     QByteArray responseData = reply->readAll();
      
     QJsonDocument doc = QJsonDocument::fromJson(responseData);
     
     if (doc.isNull() || !doc.isObject()) {
         WARN_AUTH("Invalid refresh response");
         clearTokens();
         emit authenticationChanged(false);
         return;
     }
     
     QJsonObject obj = doc.object();
     
     // Update tokens
     QString newAccessToken = obj["access_token"].toString();
     QString newRefreshToken = obj["refresh_token"].toString();
     
     if (newAccessToken.isEmpty()) {
         WARN_AUTH("Failed to get new access token");
         clearTokens();
         emit authenticationChanged(false);
         return;
     }
     
     m_accessToken = newAccessToken;
     
     // Twitch may return a new refresh token, or keep the old one
     if (!newRefreshToken.isEmpty()) {
         m_refreshToken = newRefreshToken;
         LOG_AUTH("Token refreshed (new refresh token)");
     } else {
         LOG_AUTH("Token refreshed");
     }
     
      
     saveTokens();
     
     emit authenticationChanged(true);
     emit tokenRefreshed();
     emit statusMessage("Authentication refreshed successfully!");
 }
 
 void TwitchAuthManager::logout()
 {
     LOG_AUTH("Logging out");
     stopPolling();
     clearTokens();
     emit authenticationChanged(false);
     emit statusMessage("Logged out");
 }

 void TwitchAuthManager::saveTokens()
{
       
    m_settings->setValue("auth/access_token", m_accessToken);
    m_settings->setValue("auth/refresh_token", m_refreshToken);
    m_settings->sync();
    
   }
 
 void TwitchAuthManager::loadTokens()
 {
        
     m_accessToken = m_settings->value("auth/access_token").toString();
     m_refreshToken = m_settings->value("auth/refresh_token").toString();
     
     if (!m_accessToken.isEmpty()) {
       } else {
      }
     
     if (!m_refreshToken.isEmpty()) {
      } else {
      }
 }
 
 void TwitchAuthManager::clearTokens()
 {
     m_accessToken.clear();
     m_refreshToken.clear();
     m_settings->remove("auth/access_token");
     m_settings->remove("auth/refresh_token");
     m_settings->sync();
  }