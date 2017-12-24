/*-
 * Copyright (c) 2017-2017 Artem Anufrij <artem.anufrij@live.de>
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
        PlayMyVideos.Settings settings;

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

        construct {
            settings = PlayMyVideos.Settings.get_default ();
            settings.notify["repeat-mode"].connect (() => {
                set_repeat_symbol ();
            });
        }

        public VideoTimeLine (Views.PlayerView player_view) {
            this.player_view = player_view;
            build_ui ();
            this.player_view.duration_changed.connect ((duration) => {
                timeline.playback_duration = duration;
                player_view.playback.subtitle_track = -1;
                load_audio_streams ();
                load_subtitle_tracks ();
            });
            this.player_view.progress_changed.connect ((progress) => {
                timeline.playback_progress = progress;
            });
            this.player_view.toggled.connect ((playing) => {
                if (playing) {
                    play_button.image = icon_pause;
                } else {
                    play_button.image = icon_play;
                }
            });
        }

        private void build_ui () {
            this.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            timeline = new Granite.SeekBar (0);
            timeline.hexpand = true;
            timeline.valign = Gtk.Align.CENTER;
            timeline.scale.change_value.connect ((scroll, new_value) => {
                if (scroll == Gtk.ScrollType.JUMP) {
                    player_view.playback.progress = new_value;
                }
                return false;
            });
            /*timeline.scale.enter_notify_event.connect ((event) => {
                preview_popover.schedule_show ();
                return false;
            });
            timeline.scale.leave_notify_event.connect ((event) => {
                preview_popover.schedule_hide ();
                return false;
            });*/
            timeline.scale.motion_notify_event.connect ((event) => {
                stdout.printf ("%f\n", event.x / ((double) event.window.get_width ()));
                //preview_popover.update_pointing ((int) event.x);
                //preview_popover.set_preview_progress (event.x / ((double) event.window.get_width ()), !main_playback.playing);
                return false;
            });

            icon_play = new Gtk.Image.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.MENU);
            icon_pause = new Gtk.Image.from_icon_name ("media-playback-pause-symbolic", Gtk.IconSize.MENU);

            play_button = new Gtk.Button ();
            play_button.image = icon_play;
            play_button.can_focus = false;
            play_button.clicked.connect (() => { player_view.toogle_playing (); });

            audio_stream = new Gtk.Button.from_icon_name ("config-language-symbolic", Gtk.IconSize.MENU);
            audio_stream.can_focus = false;
            audio_stream.clicked.connect (() => {
                audio_stream_popover.show_all ();
            });
            audio_stream_popover =  new Gtk.Popover(audio_stream);
            audio_streams = new Gtk.ListBox ();
            audio_streams.row_activated.connect ((row) => {
                int i = 0;
                foreach (var child in audio_streams.get_children ()) {
                    if (child == row) {
                        player_view.playback.audio_stream = i;
                        return;
                    }
                    i++;
                }
            });
            audio_stream_popover.add (audio_streams);

            subtitle_track = new Gtk.Button.from_icon_name ("media-view-subtitles-symbolic", Gtk.IconSize.MENU);
            subtitle_track.can_focus = false;
            subtitle_track.clicked.connect (() => {
                subtitle_track_popover.show_all ();
            });
            subtitle_track_popover = new Gtk.Popover(subtitle_track);
            subtitle_tracks = new Gtk.ListBox ();
            subtitle_tracks.row_activated.connect ((row) => {
                int i = -1;
                foreach (var child in subtitle_tracks.get_children ()) {
                    if (child == row) {
                        if (child is SubTitleRow) {
                            var uri = (child as SubTitleRow).get_uri ();
                            player_view.playback.subtitle_uri = uri;
                        } else {
                            player_view.playback.subtitle_track = i;
                        }
                        return;
                    }
                    i++;
                }
                subtitle_track_popover.hide ();
            });
            subtitle_track_popover.add (subtitle_tracks);

            icon_repeat_one = new Gtk.Image.from_icon_name ("media-playlist-repeat-one-symbolic", Gtk.IconSize.BUTTON);
            icon_repeat_all = new Gtk.Image.from_icon_name ("media-playlist-repeat-symbolic", Gtk.IconSize.BUTTON);
            icon_repeat_off = new Gtk.Image.from_icon_name ("media-playlist-no-repeat-symbolic", Gtk.IconSize.BUTTON);

            repeat_button = new Gtk.Button ();
            set_repeat_symbol ();
            repeat_button.tooltip_text = _("Repeat");
            repeat_button.can_focus = false;
            repeat_button.clicked.connect (() => {
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
                foreach (string stream in player_view.playback.audio_streams) {
                    var lab = new Gtk.Label ("");
                    lab.label = _("Track %d (%s)").printf (++i, stream.to_ascii ());
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

            if (player_view.playback.subtitle_tracks.length () > 0 || player_view.current_video.local_subtitles.length () > 0) {
                int i = 0;
                var lab = new Gtk.Label (_("disable"));
                lab.margin = 4;
                lab.halign = Gtk.Align.START;
                var row = new Gtk.ListBoxRow ();
                row.add (lab);
                subtitle_tracks.add (row);
                row.show_all ();

                foreach (string? subtitle in player_view.playback.subtitle_tracks) {
                    if (subtitle == null) {
                        continue;
                    }
                    lab = new Gtk.Label ("");
                    lab.label = _("Subtitle %d (%s)").printf (++i, subtitle.to_ascii ());
                    lab.margin = 4;
                    lab.halign = Gtk.Align.START;
                    row = new Gtk.ListBoxRow ();
                    row.add (lab);
                    subtitle_tracks.add (row);
                    row.show_all ();
                }

                foreach (string subtitle in player_view.current_video.local_subtitles) {
                    subtitle_tracks.add (new SubTitleRow (player_view.current_video, subtitle));
                    row.show_all ();
                }

                subtitle_track.show ();
            } else {
                subtitle_track.hide ();
            }
        }

        private void set_repeat_symbol () {
            switch (settings.repeat_mode) {
                case RepeatMode.ALL:
                    repeat_button.set_image (icon_repeat_all);
                    break;
                case RepeatMode.ONE:
                    repeat_button.set_image (icon_repeat_one);
                    break;
                default:
                    repeat_button.set_image (icon_repeat_off);
                    break;
            }
            repeat_button.show_all ();
        }
    }
}
