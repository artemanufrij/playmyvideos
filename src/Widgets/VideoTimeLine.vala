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

        public VideoTimeLine (Views.PlayerView player_view) {
            this.player_view = player_view;
            build_ui ();
            this.player_view.duration_changed.connect ((duration) => {
                timeline.playback_duration = duration;
            });
            this.player_view.progress_changed.connect ((progress) => {
                timeline.playback_progress = progress;
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

            var lang_button = new Gtk.Button.from_icon_name ("config-language-symbolic", Gtk.IconSize.MENU);

            var content = new Gtk.ActionBar ();
            content.pack_start (timeline);
            content.pack_end (lang_button);
            this.add (content);
            show_all ();
        }
    }
}
