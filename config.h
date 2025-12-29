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

 #ifndef CONFIG_H
 #define CONFIG_H
 
 #include <QString>
 
 /**
  * Configuration constants for TwitchViewer
  * 
  * IMPORTANT: The actual values are defined in config.cpp
  * Copy config.cpp.example to config.cpp and add your own Twitch Client ID
  */
 class Config {
 public:
     // Your Twitch Application Client ID from https://dev.twitch.tv/console/apps
     static const QString TWITCH_CLIENT_ID;
     
     // Twitch's public Client ID (used for GraphQL and Helix API)
     static const QString TWITCH_PUBLIC_CLIENT_ID;
 };
 
 #endif // CONFIG_H