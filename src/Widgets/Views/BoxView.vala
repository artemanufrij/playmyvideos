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

namespace PlayMyVideos.Widgets.Views {
    public class BoxView : Gtk.Grid {
        PlayMyVideos.Services.LibraryManager library_manager;
        PlayMyVideos.Settings settings;
        public PlayMyVideos.Objects.Box current_box { get; private set; }

        public signal void video_selected (Objects.Video video);
        public signal void box_removed ();

        Gtk.ListBox videos;
        Gtk.Image cover;
        Gtk.Menu menu;

        construct {
            library_manager = PlayMyVideos.Services.LibraryManager.instance;
            settings = PlayMyVideos.Settings.get_default ();
        }

        public BoxView () {
            build_ui ();
        }

        private void build_ui () {
            var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            content.width_request = 256;
            content.vexpand = true;

            var event_box = new Gtk.EventBox ();
            event_box.button_press_event.connect (show_context_menu);

            cover = new Gtk.Image ();
            event_box.add (cover);

            menu = new Gtk.Menu ();
            var menu_new_cover = new Gtk.MenuItem.with_label (_("Set new Cover…"));
            menu_new_cover.activate.connect (() => {
                var new_cover = library_manager.choose_new_cover ();
                if (new_cover != null) {
                    try {
                        var pixbuf = new Gdk.Pixbuf.from_file (new_cover);
                        current_box.set_new_cover (pixbuf);
                        if (settings.save_custom_covers) {
                            current_box.set_custom_cover_file (new_cover);
                        }
                    } catch (Error err) {
                        warning (err.message);
                    }
                }
            });
            menu.append (menu_new_cover);
            menu.show_all ();

            var videos_scroll = new Gtk.ScrolledWindow (null, null);

            videos = new Gtk.ListBox ();
            videos.set_sort_func (videos_sort_func);
            videos.selected_rows_changed.connect (play_video);
            videos_scroll.add (videos);

            content.pack_start (event_box, false, false, 0);
            content.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false);
            content.pack_start (videos_scroll, true, true, 0);
            this.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 0, 0);
            this.attach (content, 1, 0);
        }

        public void show_box (PlayMyVideos.Objects.Box box) {
            if (current_box == box) {
                return;
            }

            if (current_box != null) {
                current_box.video_added.disconnect (add_video);
                current_box.cover_changed.disconnect (change_cover);
                current_box.removed.disconnect (current_box_removed);
            }

            current_box = box;
            reset ();

            cover.pixbuf = current_box.cover;

            foreach (var video in current_box.videos) {
                add_video (video);
            }
            current_box.cover_changed.connect (change_cover);
            current_box.video_added.connect (add_video);
            current_box.removed.connect (current_box_removed);
        }

        private void current_box_removed () {
            box_removed ();
        }

        private void change_cover () {
            cover.pixbuf = current_box.cover;
        }

        private void play_video () {
            var selected_row = videos.get_selected_row ();
            if (selected_row != null) {
                video_selected ((selected_row as Widgets.Video).video);
                videos.unselect_all ();
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

        public void reset () {
            this.cover.clear ();
            foreach (var child in videos.get_children ()) {
                child.destroy ();
            }
        }

        private bool show_context_menu (Gtk.Widget sender, Gdk.EventButton evt) {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                menu.popup_at_pointer (null);
                return true;
            }
            return false;
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
