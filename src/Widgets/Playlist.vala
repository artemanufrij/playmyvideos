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
    public class Playlist : Gtk.Revealer {
        Views.PlayerView player_view;
        public Objects.Box current_box { get; private set; }

        Gtk.ListBox videos;

        bool only_mark = false;

        public bool has_episodes {
            get {
                return videos.get_children ().length () > 1;
            }
        }

        public Playlist (Views.PlayerView player_view) {
            this.player_view = player_view;
            this.player_view.started.connect ((video) => {
                mark_playing_video (video);
            });
            build_ui ();
        }

        private void build_ui () {
            this.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
            this.margin_bottom = 30;
            var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            content.get_style_context ().add_class ("card");
            content.margin = 8;
            content.width_request = 256;

            var videos_scroll = new Gtk.ScrolledWindow (null, null);
            videos = new Gtk.ListBox ();
            videos.set_sort_func (videos_sort_func);
            videos.selected_rows_changed.connect (play_video);
            videos_scroll.add (videos);

            content.pack_start (videos_scroll, true, true, 0);

            this.add (content);
            this.show_all ();
        }

        public void show_box (Objects.Box box) {
            if (current_box == box) {
                return;
            }
            current_box = box;
            reset ();
            foreach (var video in box.videos) {
                add_video (video);
            }
            this.show_all ();
        }

        private void add_video (Objects.Video video) {
            var row = new Widgets.Video (video);
            videos.add (row);
            row.show_all ();
        }

        private void reset () {
            foreach (var child in videos.get_children ()) {
                child.destroy ();
            }
        }

        private void play_video () {
            var selected_row = videos.get_selected_row ();
            if (selected_row != null && !only_mark) {
                player_view.play ((selected_row as Widgets.Video).video);
            }
        }

        public void mark_playing_video (Objects.Video? video) {
            videos.unselect_all ();
            if (video == null) {
                return;
            }
            foreach (var item in videos.get_children ()) {
                if ((item as Widgets.Video).video.ID == video.ID) {
                    only_mark = true;
                    item.activate ();
                    only_mark = false;
                    return;
                }
            }
        }

        public void unselect_all () {
            videos.unselect_all ();
        }

        private int videos_sort_func (Gtk.ListBoxRow child1, Gtk.ListBoxRow child2) {
            var item1 = (PlayMyVideos.Widgets.Video)child1;
            var item2 = (PlayMyVideos.Widgets.Video)child2;
            if (item1 != null && item2 != null) {
                if (item1.year != item2.year) {
                    return item1.year - item2.year;
                }
                return item1.title.collate (item2.title);
            }
            return 0;
        }
    }
}
