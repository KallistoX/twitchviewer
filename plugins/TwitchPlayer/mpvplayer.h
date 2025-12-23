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

 #ifndef MPVPLAYER_H
 #define MPVPLAYER_H
 
 #include <QObject>
 #include <QQuickFramebufferObject>
 #include <mpv/client.h>
 #include <mpv/render_gl.h>
 
 class MpvRenderer;
 
 class MpvPlayer : public QQuickFramebufferObject {
     Q_OBJECT
     Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)
     Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
     
 public:
     MpvPlayer(QQuickItem *parent = nullptr);
     ~MpvPlayer();
     
     Renderer *createRenderer() const override;
     
     QString source() const { return m_source; }
     void setSource(const QString &source);
     
     bool playing() const { return m_playing; }
     
     Q_INVOKABLE void play();
     Q_INVOKABLE void pause();
     Q_INVOKABLE void stop();
     
     mpv_handle *mpv() const { return m_mpv; }
     mpv_render_context *mpvRenderContext() const { return m_mpvRenderContext; }
     
 signals:
     void sourceChanged();
     void playingChanged();
     
 private slots:
     void onMpvEvents();
     
 private:
     void initMpv();
     static void on_mpv_events(void *ctx);
     static void on_mpv_redraw(void *ctx);
     
     mpv_handle *m_mpv;
     mpv_render_context *m_mpvRenderContext;
     QString m_source;
     bool m_playing;
 };
 
 class MpvRenderer : public QQuickFramebufferObject::Renderer {
 public:
     MpvRenderer(MpvPlayer *player);
     ~MpvRenderer();
     
     QOpenGLFramebufferObject *createFramebufferObject(const QSize &size) override;
     void render() override;
     
 private:
     MpvPlayer *m_player;
 };
 
 #endif