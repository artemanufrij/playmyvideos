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
    public class VideoTimeLine : Gtk.Grid {
        Views.PlayerView player_view;
        Granite.SeekBar timeline;
        Gtk.Popover audio_stream_popover;
        Gtk.ListBox audio_streams;

        Gtk.Button play_button;
        Gtk.Image icon_play;
        Gtk.Image icon_pause;

        public VideoTimeLine (Views.PlayerView player_view) {
            this.player_view = player_view;
            build_ui ();
            this.player_view.duration_changed.connect ((duration) => {
                timeline.playback_duration = duration;

                foreach (var row in audio_streams.get_children ()) {
                    row.destroy ();
                }
                foreach (var stream in player_view.playback.audio_streams) {
                    var lab = new Gtk.Label (stream);
                    lab.margin = 4;
                    var row = new Gtk.ListBoxRow ();
                    row.add (lab);
                    audio_streams.add (row);
                    row.show_all ();
                }
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
            timeline = new Granite.SeekBar (0);
            timeline.hexpand = true;
            timeline.valign = Gtk.Align.CENTER;
            timeline.scale.change_value.connect ((scroll, new_value) => {
                if (scroll == Gtk.ScrollType.JUMP) {
                    player_view.playback.progress = new_value;
                }
                return false;
            });

            icon_play = new Gtk.Image.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.MENU);
            icon_pause = new Gtk.Image.from_icon_name ("media-playback-pause-symbolic", Gtk.IconSize.MENU);

            play_button = new Gtk.Button ();
            play_button.image = icon_play;
            play_button.can_focus = false;
            play_button.clicked.connect (() => { player_view.toogle_playing (); });

            var audio_stream = new Gtk.Button.from_icon_name ("config-language-symbolic", Gtk.IconSize.MENU);
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

            var content = new Gtk.ActionBar ();
            content.pack_start (play_button);
            content.pack_start (timeline);
            content.pack_end (audio_stream);
            this.add (content);
            show_all ();
        }
    }
}
