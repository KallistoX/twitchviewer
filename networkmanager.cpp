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

#include "networkmanager.h"
#include "logging.h"
#include <QNetworkRequest>

NetworkManager::NetworkManager(QObject *parent)
    : QObject(parent)
    , m_netConfig(new QNetworkConfigurationManager(this))
    , m_isOnline(true)
    , m_wasOnline(true)
    , m_statusMessage("Online")
    , m_hasActiveError(false)
{
    m_isOnline = m_netConfig->isOnline();
    m_wasOnline = m_isOnline;

    LOG_NETWORK((m_isOnline ? "Online" : "Offline"));

    connect(m_netConfig, &QNetworkConfigurationManager::onlineStateChanged,
            this, &NetworkManager::onOnlineStateChanged);

    setStatusMessage(m_isOnline ? "Online" : "Offline - No internet connection");
}

NetworkManager::~NetworkManager()
{
}

void NetworkManager::onOnlineStateChanged(bool online)
{
    bool wasOnline = m_isOnline;
    m_isOnline = online;

    setStatusMessage(online ? "Online" : "Offline - No internet connection");
    emit onlineStatusChanged(online);

    if (online && !wasOnline) {
        LOG_NETWORK("Connection restored");
        clearError();
        emit connectionRestored();
    } else if (!online && wasOnline) {
        LOG_NETWORK("Connection lost");
        emit connectionLost();
    }
}

void NetworkManager::setStatusMessage(const QString &message)
{
    if (m_statusMessage != message) {
        m_statusMessage = message;
        emit statusMessageChanged(message);
    }
}

void NetworkManager::reportError(ErrorType errorType)
{
    if (errorType == NetworkError && !m_hasActiveError) {
        m_hasActiveError = true;
        emit activeErrorChanged(true);
    }
}

void NetworkManager::clearError()
{
    if (m_hasActiveError) {
        m_hasActiveError = false;
        emit activeErrorChanged(false);
    }
}

void NetworkManager::reportSuccess()
{
    // Clear any active error
    if (m_hasActiveError) {
        clearError();
    }

    // Update online status if we were offline
    // This is important for cases where QNetworkConfigurationManager
    // incorrectly reports offline status (e.g., due to AppArmor restrictions)
    if (!m_isOnline) {
        m_isOnline = true;
        setStatusMessage("Online");
        emit onlineStatusChanged(true);
        emit connectionRestored();
        LOG_NETWORK("Connection restored (successful request)");
    }
}

NetworkManager::ErrorType NetworkManager::classifyError(QNetworkReply *reply)
{
    if (!reply) {
        WARN_NETWORK("classifyError called with null reply");
        return UnknownError;
    }

    if (reply->error() == QNetworkReply::NoError) {
        if (m_hasActiveError) {
            clearError();
        }
        if (!m_isOnline) {
            m_isOnline = true;
            setStatusMessage("Online");
            emit onlineStatusChanged(true);
            emit connectionRestored();
            LOG_NETWORK("Connection restored");
        }
        return NoError;
    }

    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QNetworkReply::NetworkError netError = reply->error();

    // Network connectivity issues
    if (netError == QNetworkReply::HostNotFoundError ||
        netError == QNetworkReply::TimeoutError ||
        netError == QNetworkReply::TemporaryNetworkFailureError ||
        netError == QNetworkReply::NetworkSessionFailedError ||
        netError == QNetworkReply::UnknownNetworkError ||
        netError == QNetworkReply::ConnectionRefusedError ||
        netError == QNetworkReply::OperationCanceledError) {

        if (m_isOnline) {
            m_isOnline = false;
            setStatusMessage("Offline - No internet connection");
            emit onlineStatusChanged(false);
            emit connectionLost();
            WARN_NETWORK("Connection lost");
        }

        reportError(NetworkError);
        return NetworkError;
    }

    // HTTP 401/403: Authentication errors
    if (statusCode == 401 || statusCode == 403) {
        return AuthError;
    }

    // HTTP 5xx: Server errors
    if (statusCode >= 500 && statusCode < 600) {
        return ServerError;
    }

    // HTTP 4xx: Client errors
    if (statusCode >= 400 && statusCode < 500) {
        return ClientError;
    }

    // SSL/TLS errors
    if (netError >= QNetworkReply::SslHandshakeFailedError &&
        netError <= QNetworkReply::UnknownContentError) {
        return NetworkError;
    }

    return UnknownError;
}

QString NetworkManager::getErrorMessage(QNetworkReply *reply)
{
    if (!reply) {
        return "Unknown error";
    }
    
    ErrorType type = classifyError(reply);
    
    switch (type) {
        case NoError:
            return "Request successful";
            
        case NetworkError:
            return "No internet connection - Please check your network";
            
        case AuthError: {
            int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            if (statusCode == 401) {
                return "Authentication failed - Token expired, please login again";
            } else if (statusCode == 403) {
                return "Access denied - Token doesn't have required permissions";
            }
            return "Authentication error";
        }
            
        case ServerError:
            return "Twitch servers are having issues - Please try again later";
            
        case ClientError: {
            int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            return QString("Request error (HTTP %1) - %2")
                .arg(statusCode)
                .arg(reply->errorString());
        }
            
        case UnknownError:
            return "An unknown error occurred: " + reply->errorString();
    }
    
    return "Unknown error";
}

bool NetworkManager::isRetryableError(ErrorType errorType)
{
    switch (errorType) {
        case NetworkError:
            // Retry when internet comes back
            return true;
            
        case ServerError:
            // Retry when Twitch servers recover
            return true;
            
        case AuthError:
            // Don't auto-retry - user needs to login again
            return false;
            
        case ClientError:
            // Don't retry - bad request won't succeed
            return false;
            
        case UnknownError:
            // Unknown errors - don't retry to be safe
            return false;
            
        case NoError:
            return false;
    }
    
    return false;
}