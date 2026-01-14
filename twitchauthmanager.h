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

 #ifndef TWITCHAUTHMANAGER_H
 #define TWITCHAUTHMANAGER_H
 
 #include <QObject>
 #include <QString>
 #include <QNetworkAccessManager>
 #include <QNetworkReply>
 #include <QTimer>
 #include <QSettings>
 class NetworkManager;

 /**
  * Manages Twitch OAuth authentication using Device Flow
  * 
  * Device Flow is ideal for devices without a full browser:
  * 1. App requests a device code
  * 2. User visits twitch.tv/activate on another device
  * 3. User enters the code shown in the app
  * 4. App polls for token until user authorizes
  * 5. Token is saved and used for authenticated API requests
  * 
  * Token Refresh:
  * - Access tokens expire after ~4 hours
  * - Refresh tokens are used to get new access tokens
  * - Refresh tokens expire after ~60 days of inactivity
  */
 class TwitchAuthManager : public QObject
 {
     Q_OBJECT
     
     // QML Properties
     Q_PROPERTY(bool isAuthenticated READ isAuthenticated NOTIFY authenticationChanged)
     Q_PROPERTY(QString userCode READ userCode NOTIFY userCodeChanged)
     Q_PROPERTY(QString verificationUrl READ verificationUrl NOTIFY verificationUrlChanged)
     Q_PROPERTY(bool isPolling READ isPolling NOTIFY pollingChanged)
 
 public:
     explicit TwitchAuthManager(QObject *parent = nullptr);
     ~TwitchAuthManager();
 
     // Property getters
     bool isAuthenticated() const { return !m_accessToken.isEmpty(); }
     QString userCode() const { return m_userCode; }
     QString verificationUrl() const { return m_verificationUrl; }
     bool isPolling() const { return m_isPolling; }
     
     // Access token for API requests
     QString accessToken() const { return m_accessToken; }

     void setNetworkManager(NetworkManager *networkManager);
 
 public slots:
     // Start OAuth Device Flow
     void startDeviceAuth();
     
     // Logout and clear stored token
     void logout();
     
     // Validate existing token
     void validateToken();
 
     // Refresh access token using refresh token
     void refreshAccessToken();
 
 signals:
     // Authentication state changed
     void authenticationChanged(bool authenticated);
     
     // Device code received - user should visit verification URL
     void userCodeChanged(QString code);
     void verificationUrlChanged(QString url);
     
     // Polling state changed
     void pollingChanged(bool polling);
     
     // Auth completed successfully
     void authenticationSucceeded();
     
     // Error occurred
     void authenticationFailed(QString message);
     
     // Status updates for UI
     void statusMessage(QString message);
 
     // Token refresh completed
     void tokenRefreshed();
 
 private slots:
     // Handle device code response
     void onDeviceCodeReceived();
     
     // Handle token response
     void onTokenReceived();
     
     // Handle token validation response
     void onTokenValidated();
     
     // Poll for token
     void pollForToken();
 
     // Handle refresh token response
     void onRefreshTokenReceived();
 
 private:
     // Network manager
     QNetworkAccessManager *m_networkManager;
     
     // Polling timer
     QTimer *m_pollTimer;
     
     // Settings for token persistence
     QSettings *m_settings;
     
     // OAuth flow state
     QString m_deviceCode;
     QString m_userCode;
     QString m_verificationUrl;
     int m_expiresIn;
     int m_interval;
     bool m_isPolling;
     
     // Tokens
     QString m_accessToken;
     QString m_refreshToken;
     
     // Twitch API endpoints
     static const QString TWITCH_DEVICE_URL;
     static const QString TWITCH_TOKEN_URL;
     static const QString TWITCH_VALIDATE_URL;
     
     // OAuth scopes
     static const QString OAUTH_SCOPES;
     
     // Helper methods
     void saveTokens();
     void loadTokens();
     void clearTokens();
     void startPolling();
     void stopPolling();

     NetworkManager *m_netStatusManager;
 };
 
 #endif // TWITCHAUTHMANAGER_H