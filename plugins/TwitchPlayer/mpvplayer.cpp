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

 #include "mpvplayer.h"
 #include <QOpenGLFramebufferObject>
 #include <QQuickWindow>
 #include <QDebug>
 
 static void *get_proc_address_mpv(void *ctx, const char *name) {
     Q_UNUSED(ctx)
     QOpenGLContext *glctx = QOpenGLContext::currentContext();
     if (!glctx) return nullptr;
     return reinterpret_cast<void *>(glctx->getProcAddress(QByteArray(name)));
 }
 
 MpvPlayer::MpvPlayer(QQuickItem *parent)
     : QQuickFramebufferObject(parent)
     , m_mpv(nullptr)
     , m_mpvRenderContext(nullptr)
     , m_playing(false)
 {
     initMpv();
 }
 
 MpvPlayer::~MpvPlayer() {
     if (m_mpvRenderContext) {
         mpv_render_context_free(m_mpvRenderContext);
     }
     if (m_mpv) {
         mpv_terminate_destroy(m_mpv);
     }
 }
 
 void MpvPlayer::initMpv() {
     m_mpv = mpv_create();
     if (!m_mpv) {
         qWarning() << "Failed to create MPV instance";
         return;
     }
     
     // Set some basic options
     mpv_set_option_string(m_mpv, "terminal", "yes");
     mpv_set_option_string(m_mpv, "msg-level", "all=v");
     
     // Hardware decoding
     mpv_set_option_string(m_mpv, "hwdec", "auto");
     
     // Initialize
     if (mpv_initialize(m_mpv) < 0) {
         qWarning() << "Failed to initialize MPV";
         return;
     }
     
     // Setup event handling
     mpv_set_wakeup_callback(m_mpv, on_mpv_events, this);
     
     qDebug() << "MPV initialized successfully";
 }
 
 void MpvPlayer::setSource(const QString &source) {
     if (m_source == source) return;
     
     m_source = source;
     emit sourceChanged();
     
     if (!source.isEmpty() && m_mpv) {
         const char *cmd[] = {"loadfile", source.toUtf8().data(), nullptr};
         mpv_command_async(m_mpv, 0, cmd);
         qDebug() << "Loading source:" << source;
     }
 }
 
 void MpvPlayer::play() {
     if (m_mpv) {
         int flag = 0;
         mpv_set_property_async(m_mpv, 0, "pause", MPV_FORMAT_FLAG, &flag);
         m_playing = true;
         emit playingChanged();
     }
 }
 
 void MpvPlayer::pause() {
     if (m_mpv) {
         int flag = 1;
         mpv_set_property_async(m_mpv, 0, "pause", MPV_FORMAT_FLAG, &flag);
         m_playing = false;
         emit playingChanged();
     }
 }
 
 void MpvPlayer::stop() {
     if (m_mpv) {
         const char *cmd[] = {"stop", nullptr};
         mpv_command_async(m_mpv, 0, cmd);
         m_playing = false;
         emit playingChanged();
     }
 }
 
 void MpvPlayer::on_mpv_events(void *ctx) {
     QMetaObject::invokeMethod(static_cast<MpvPlayer*>(ctx), "onMpvEvents");
 }
 
 void MpvPlayer::on_mpv_redraw(void *ctx) {
     QMetaObject::invokeMethod(static_cast<MpvPlayer*>(ctx), "update");
 }
 
 void MpvPlayer::onMpvEvents() {
     while (m_mpv) {
         mpv_event *event = mpv_wait_event(m_mpv, 0);
         if (event->event_id == MPV_EVENT_NONE) break;
         
         switch (event->event_id) {
             case MPV_EVENT_PLAYBACK_RESTART:
                 qDebug() << "Playback started";
                 m_playing = true;
                 emit playingChanged();
                 break;
             case MPV_EVENT_PAUSE:
                 qDebug() << "Playback paused";
                 m_playing = false;
                 emit playingChanged();
                 break;
             case MPV_EVENT_END_FILE:
                 qDebug() << "Playback ended";
                 m_playing = false;
                 emit playingChanged();
                 break;
             case MPV_EVENT_LOG_MESSAGE: {
                 mpv_event_log_message *msg = static_cast<mpv_event_log_message*>(event->data);
                 qDebug() << "[MPV]" << msg->prefix << msg->level << msg->text;
                 break;
             }
             default:
                 break;
         }
     }
 }
 
 QQuickFramebufferObject::Renderer *MpvPlayer::createRenderer() const {
     window()->setPersistentOpenGLContext(true);
     window()->setPersistentSceneGraph(true);
     return new MpvRenderer(const_cast<MpvPlayer*>(this));
 }
 
 // Renderer implementation
 MpvRenderer::MpvRenderer(MpvPlayer *player)
     : m_player(player)
 {
     if (!m_player->mpv()) return;
     
     mpv_opengl_init_params gl_init_params{get_proc_address_mpv, nullptr};
     mpv_render_param params[]{
         {MPV_RENDER_PARAM_API_TYPE, const_cast<char *>(MPV_RENDER_API_TYPE_OPENGL)},
         {MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &gl_init_params},
         {MPV_RENDER_PARAM_INVALID, nullptr}
     };
     
     if (mpv_render_context_create(&m_player->m_mpvRenderContext, m_player->mpv(), params) < 0) {
         qWarning() << "Failed to create MPV render context";
         return;
     }
     
     mpv_render_context_set_update_callback(m_player->mpvRenderContext(), 
                                            MpvPlayer::on_mpv_redraw, 
                                            m_player);
 }
 
 MpvRenderer::~MpvRenderer() {
 }
 
 QOpenGLFramebufferObject *MpvRenderer::createFramebufferObject(const QSize &size) {
     return QQuickFramebufferObject::Renderer::createFramebufferObject(size);
 }
 
 void MpvRenderer::render() {
     if (!m_player->mpvRenderContext()) return;
     
     QOpenGLFramebufferObject *fbo = framebufferObject();
     mpv_opengl_fbo mpv_fbo{
         static_cast<int>(fbo->handle()),
         fbo->width(),
         fbo->height(),
         0
     };
     
     int flip_y = 1;
     mpv_render_param params[] = {
         {MPV_RENDER_PARAM_OPENGL_FBO, &mpv_fbo},
         {MPV_RENDER_PARAM_FLIP_Y, &flip_y},
         {MPV_RENDER_PARAM_INVALID, nullptr}
     };
     
     mpv_render_context_render(m_player->mpvRenderContext(), params);
 }