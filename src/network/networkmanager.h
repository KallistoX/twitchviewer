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

#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#include <QObject>
#include <QNetworkReply>
#include <QNetworkConfigurationManager>

/**
 * NetworkManager - Handles network connectivity state and error classification
 * 
 * Purpose: Prevent deletion of valid OAuth tokens due to temporary network issues
 * 
 * Features:
 * - Monitors online/offline status
 * - Classifies network errors (NetworkError vs AuthError vs ServerError)
 * - Provides signals for UI to show offline banners
 * - Enables smart retry logic
 */
class NetworkManager : public QObject
{
    Q_OBJECT
    
    Q_PROPERTY(bool isOnline READ isOnline NOTIFY onlineStatusChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(bool hasActiveError READ hasActiveError NOTIFY activeErrorChanged)

public:
    explicit NetworkManager(QObject *parent = nullptr);
    ~NetworkManager();
    
    // Error type classification
    enum ErrorType {
        NoError,           // Request succeeded
        NetworkError,      // No internet connection (DNS, timeout, etc.)
        AuthError,         // 401/403 - Invalid/expired token
        ServerError,       // 5xx - Server-side issues
        ClientError,       // 4xx (other than 401/403) - Bad request
        UnknownError       // Other errors
    };
    Q_ENUM(ErrorType)
    
    // Property getters
    bool isOnline() const { return m_isOnline; }
    QString statusMessage() const { return m_statusMessage; }

    bool hasActiveError() const { return m_hasActiveError; }
    
    // Call this from error handlers
    Q_INVOKABLE void reportError(ErrorType errorType);
    Q_INVOKABLE void clearError();
    Q_INVOKABLE void reportSuccess();  // Call this after successful network requests
    
    /**
     * Classify network reply error
     * 
     * This is the KEY function that prevents token deletion on network errors!
     * 
     * @param reply QNetworkReply to analyze
     * @return ErrorType classification
     */
    Q_INVOKABLE ErrorType classifyError(QNetworkReply *reply);
    
    /**
     * Get human-readable error message
     * 
     * @param reply QNetworkReply to analyze
     * @return User-friendly error message
     */
    Q_INVOKABLE QString getErrorMessage(QNetworkReply *reply);
    
    /**
     * Check if error is retryable
     * 
     * NetworkError and ServerError are retryable.
     * AuthError typically requires user action (login again).
     * 
     * @param errorType Error type from classifyError()
     * @return true if should retry, false otherwise
     */
    Q_INVOKABLE bool isRetryableError(ErrorType errorType);

signals:
    // Emitted when online status changes
    void onlineStatusChanged(bool online);
    
    // Emitted when connection is restored after being offline
    void connectionRestored();
    
    // Emitted when connection is lost
    void connectionLost();
    
    // Emitted when status message changes
    void statusMessageChanged(QString message);

    void activeErrorChanged(bool hasError);

private slots:
    // Handle network configuration changes
    void onOnlineStateChanged(bool online);

private:
    QNetworkConfigurationManager *m_netConfig;
    bool m_isOnline;
    bool m_wasOnline;  // Track previous state for connectionRestored signal
    QString m_statusMessage;
    
    void setStatusMessage(const QString &message);
    bool m_hasActiveError;
};

#endif // NETWORKMANAGER_H