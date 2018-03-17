/*-
 * Copyright (c) 2017-2018 Artem Anufrij <artem.anufrij@live.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Artem Anufrij <artem.anufrij@live.de>
 */

namespace PlayMyVideos.Widgets {
    public class VideoTimeLine : Gtk.Revealer {
        Services.LibraryManager library_manager;
        Settings settings;

        public bool is_mouse_over { get; private set; }

        Views.PlayerView player_view;
        Granite.SeekBar timeline;
        Gtk.Button audio_stream;
        Gtk.Popover audio_stream_popover;
        Gtk.ListBox audio_streams;
        Gtk.Button subtitle_track;
        Gtk.Popover subtitle_track_popover;
        Gtk.ListBox subtitle_tracks;
        Gtk.Button repeat_button;

        Gtk.Button play_button;
        Gtk.Image icon_play;
        Gtk.Image icon_pause;

        Gtk.Image icon_repeat_one;
        Gtk.Image icon_repeat_all;
        Gtk.Image icon_repeat_off;

        Widgets.PreviewPopover preview_popover;

        uint popover_timer_id = 0;

        construct {
            settings = Settings.get_default ();
            settings.notify["repeat-mode"].connect (
                () => {
                    set_repeat_symbol ();
                });
            library_manager = Services.LibraryManager.instance;
        }

        public VideoTimeLine (Views.PlayerView player_view) {
            this.player_view = player_view;
            build_ui ();
            this.player_view.duration_changed.connect (
                (duration) => {
                    timeline.playback_duration = duration;
                    player_view.playback.subtitle_track = -1;
                    load_audio_streams ();
                    load_subtitle_tracks ();
                });
            this.player_view.progress_changed.connect (
                (progress) => {
                    timeline.playback_progress = progress;
                });
            this.player_view.toggled.connect (
                (playing) => {
                    if (playing) {
                        play_button.image = icon_pause;
                    } else {
                        play_button.image = icon_play;
                    }
                });
            this.player_view.started.connect (
                (video) => {
                    if (preview_popover.current_video != video) {
                        preview_popover.current_video = video;
                    }
                });
        }

        private void build_ui () {
            this.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            this.events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;
            this.events |= Gdk.EventMask.ENTER_NOTIFY_MASK;
            this.events |= Gdk.EventMask.POINTER_MOTION_MASK;

            this.enter_notify_event.connect (
                (event) => {
                    is_mouse_over = true;
                    return false;
                });
            this.leave_notify_event.connect (
                (event) => {
                    is_mouse_over = false;
                    if (popover_timer_id > 0) {
                        Source.remove (popover_timer_id);
                        popover_timer_id = 0;
                    }
                    return false;
                });
            this.motion_notify_event.connect (
                (event) => {
                    is_mouse_over = true;
                    return false;
                });

            timeline = new Granite.SeekBar (0);
            timeline.hexpand = true;
            timeline.valign = Gtk.Align.CENTER;
            timeline.scale.change_value.connect (
                (scroll, new_value) => {
                    if (scroll == Gtk.ScrollType.JUMP) {
                        player_view.playback.progress = new_value;
                    }
                    return false;
                });
            timeline.scale.leave_notify_event.connect (
                (event) => {
                    preview_popover.hide ();
                    return false;
                });
            timeline.scale.motion_notify_event.connect (
                (event) => {
                    preview_popover.hide ();
                    is_mouse_over = true;

                    if (popover_timer_id > 0) {
                        Source.remove (popover_timer_id);
                        popover_timer_id = 0;
                    }

                    popover_timer_id = Timeout.add (
                        300,
                        () => {
                            popover_timer_id = 0;
                            if (is_mouse_over) {
                                preview_popover.update_position ((int)event.x);
                                preview_popover.preview_progress ((event.x - 8) / ((double)timeline.scale.get_allocated_width () - 16));
                            }
                            return false;
                        });

                    return false;
                });

            preview_popover = new Widgets.PreviewPopover ();
            preview_popover.relative_to = timeline.scale;

            icon_play = new Gtk.Image.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.MENU);
            icon_pause = new Gtk.Image.from_icon_name ("media-playback-pause-symbolic", Gtk.IconSize.MENU);

            play_button = new Gtk.Button ();
            play_button.image = icon_play;
            play_button.can_focus = false;
            play_button.clicked.connect (
                () => { player_view.toogle_playing (); });

            audio_stream = new Gtk.Button.from_icon_name ("config-language-symbolic", Gtk.IconSize.MENU);
            audio_stream.can_focus = false;
            audio_stream.clicked.connect (
                () => {
                    audio_stream_popover.show_all ();
                });
            audio_stream_popover =  new Gtk.Popover (audio_stream);
            audio_streams = new Gtk.ListBox ();
            audio_streams.row_activated.connect (
                (row) => {
                    int i = 0;
                    foreach (var child in audio_streams.get_children ()) {
                        if (child == row) {
                            player_view.playback.audio_stream = i;
                            break;
                        }
                        i++;
                    }
                    audio_stream_popover.hide ();
                });
            audio_stream_popover.add (audio_streams);

            subtitle_track = new Gtk.Button.from_icon_name ("media-view-subtitles-symbolic", Gtk.IconSize.MENU);
            subtitle_track.can_focus = false;
            subtitle_track.clicked.connect (
                () => {
                    subtitle_track_popover.show_all ();
                });
            subtitle_track_popover = new Gtk.Popover (subtitle_track);
            subtitle_tracks = new Gtk.ListBox ();
            subtitle_tracks.row_activated.connect (
                (row) => {
                    if (row is SubTitleRow) {
                        var uri = (row as SubTitleRow).uri;
                        player_view.playback.subtitle_track = 0;
                        player_view.playback.subtitle_uri = uri;
                    } else {
                        int i = subtitle_tracks.get_children ().index (row) - 1;
                        player_view.playback.subtitle_uri = "";
                        player_view.playback.subtitle_track = i;
                    }
                    subtitle_track_popover.hide ();
                });

            var open_external_subtitle = new Gtk.Button.from_icon_name ("document-open-symbolic", Gtk.IconSize.BUTTON);
            open_external_subtitle.margin = 6;
            open_external_subtitle.halign = Gtk.Align.END;
            open_external_subtitle.clicked.connect (
                () => {
                    var external_subtitle = library_manager.choose_external_subtitle ();
                    if (external_subtitle != null) {
                        var new_row = new SubTitleRow (player_view.current_video, external_subtitle);
                        subtitle_tracks.add (new_row);
                        subtitle_tracks.show_all ();
                        new_row.activate ();
                    }
                });

            var subtitle_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            subtitle_container.pack_start (subtitle_tracks);
            subtitle_container.pack_start (open_external_subtitle);

            subtitle_track_popover.add (subtitle_container);

            icon_repeat_one = new Gtk.Image.from_icon_name ("media-playlist-repeat-one-symbolic", Gtk.IconSize.BUTTON);
            icon_repeat_all = new Gtk.Image.from_icon_name ("media-playlist-repeat-symbolic", Gtk.IconSize.BUTTON);
            icon_repeat_off = new Gtk.Image.from_icon_name ("media-playlist-no-repeat-symbolic", Gtk.IconSize.BUTTON);

            repeat_button = new Gtk.Button ();
            set_repeat_symbol ();
            repeat_button.tooltip_text = _ ("Repeat");
            repeat_button.can_focus = false;
            repeat_button.clicked.connect (
                () => {
                    settings.switch_repeat_mode ();
                });

            var content = new Gtk.ActionBar ();
            content.pack_start (play_button);
            content.pack_start (timeline);
            content.pack_end (repeat_button);
            content.pack_end (audio_stream);
            content.pack_end (subtitle_track);

            this.add (content);
            this.show_all ();
        }

        private void load_audio_streams () {
            foreach (var row in audio_streams.get_children ()) {
                row.destroy ();
            }

            if (player_view.playback.audio_streams.length () > 1) {
                int i = 0;
                foreach (var stream in player_view.playback.audio_streams) {
                    var lab = new Gtk.Label ("");
                    lab.label = _ ("Track %d (%s)").printf (++i, (stream == null ? "" : stream).to_ascii ());
                    lab.margin = 4;
                    var row = new Gtk.ListBoxRow ();
                    row.add (lab);
                    audio_streams.add (row);
                    row.show_all ();
                }
                audio_stream.show ();
            } else {
                audio_stream.hide ();
            }
        }

        private void load_subtitle_tracks () {
            foreach (var row in subtitle_tracks.get_children ()) {
                row.destroy ();
            }

            var lab = new Gtk.Label (_ ("disable"));
            lab.margin = 4;
            lab.halign = Gtk.Align.START;
            var row = new Gtk.ListBoxRow ();
            row.add (lab);
            subtitle_tracks.add (row);

            foreach (string ? subtitle in player_view.playback.subtitle_tracks) {
                if (subtitle == null) {
                    continue;
                }
                lab = new Gtk.Label ("");
                lab.label = _ ("Subtitle %d (%s)").printf ((int)subtitle_tracks.get_children ().length (), subtitle.to_ascii ());
                lab.margin = 4;
                lab.halign = Gtk.Align.START;
                row = new Gtk.ListBoxRow ();
                row.add (lab);
                subtitle_tracks.add (row);
            }

            foreach (string subtitle in player_view.current_video.local_subtitles) {
                subtitle_tracks.add (new SubTitleRow (player_view.current_video, subtitle));
            }

            subtitle_tracks.show_all ();
        }

        private void set_repeat_symbol () {
            switch (settings.repeat_mode) {
            case RepeatMode.ALL :
                repeat_button.set_image (icon_repeat_all);
                break;
            case RepeatMode.ONE :
                repeat_button.set_image (icon_repeat_one);
                break;
            default :
                repeat_button.set_image (icon_repeat_off);
                break;
            }
            repeat_button.show_all ();
        }
    }
}
