#ifndef LOGGING_H
#define LOGGING_H

#include <QDebug>

// Logging categories with consistent prefixes
#define LOG_AUTH(msg)     qDebug() << "[Auth]" << msg
#define LOG_NETWORK(msg)  qDebug() << "[Network]" << msg
#define LOG_API(msg)      qDebug() << "[API]" << msg
#define LOG_STREAM(msg)   qDebug() << "[Stream]" << msg
#define LOG_APP(msg)      qDebug() << "[App]" << msg

#define WARN_AUTH(msg)    qWarning() << "[Auth]" << msg
#define WARN_NETWORK(msg) qWarning() << "[Network]" << msg
#define WARN_API(msg)     qWarning() << "[API]" << msg
#define WARN_STREAM(msg)  qWarning() << "[Stream]" << msg

#define ERR_AUTH(msg)     qCritical() << "[Auth]" << msg
#define ERR_NETWORK(msg)  qCritical() << "[Network]" << msg
#define ERR_API(msg)      qCritical() << "[API]" << msg
#define ERR_STREAM(msg)   qCritical() << "[Stream]" << msg

#endif // LOGGING_H
