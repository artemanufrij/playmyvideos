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

namespace PlayMyVideos.Widgets.Views {
    public class BoxView : Gtk.Grid {
        public PlayMyVideos.Objects.Box current_box { get; private set; }

        public signal void video_selected (Objects.Video video);

        Gtk.ListBox videos;
        Gtk.Image cover;

        public BoxView () {
            build_ui ();
        }

        private void build_ui () {
            var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            content.width_request = 256;
            content.vexpand = true;

            cover = new Gtk.Image ();

            var videos_scroll = new Gtk.ScrolledWindow (null, null);

            videos = new Gtk.ListBox ();
            videos.selected_rows_changed.connect (play_video);
            videos_scroll.add (videos);

            content.pack_start (cover, false, false, 0);
            content.pack_start (videos_scroll, true, true, 0);
            var separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
            this.attach (separator, 0, 0);
            this.attach (content, 1, 0);
        }

        public void show_box (PlayMyVideos.Objects.Box box) {
            if (current_box == box) {
                return;
            }

            current_box = box;
            reset ();

            cover.pixbuf = current_box.cover;

            foreach (var video in current_box.videos) {
                add_video (video);
            }
        }

        private void play_video () {
            var selected_row = videos.get_selected_row ();
            if (selected_row != null) {
                video_selected ((selected_row as Widgets.Video).video);
            }
        }

        private void add_video (PlayMyVideos.Objects.Video video) {
            Idle.add (() => {
                var item = new PlayMyVideos.Widgets.Video (video);
                this.videos.add (item);
                item.show_all ();
                return false;
            });
        }

        private void reset () {
            foreach (var child in videos.get_children ()) {
                child.destroy ();
            }
        }
    }
}
