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

namespace PlayMyVideos {
    public class MainWindow : Gtk.Window {
        PlayMyVideos.Services.LibraryManager library_manager;
        PlayMyVideos.Settings settings;

        Gtk.HeaderBar headerbar;
        Gtk.SearchEntry search_entry;
        Gtk.Stack content;
        Gtk.Button navigation_button;
        Widgets.Views.BoxesView boxes_view;
        Widgets.Views.PlayerView player_view;

        construct {
            settings = PlayMyVideos.Settings.get_default ();
            library_manager = PlayMyVideos.Services.LibraryManager.instance;
        }

        public MainWindow () {
            events |= Gdk.EventMask.POINTER_MOTION_MASK;
            load_settings ();
            this.window_position = Gtk.WindowPosition.CENTER;
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
            build_ui ();

            load_content_from_database.begin ((obj, res) => {
                library_manager.scan_local_library (settings.library_location);
            });
            this.configure_event.connect ((event) => {
                if (!player_view.playback.playing) {
                    settings.window_width = event.width;
                    settings.window_height = event.height;
                }
                return false;
            });

            this.motion_notify_event.connect ((event) => {
                show_mouse_cursor ();
                return false;
            });

            this.destroy.connect (() => {
                save_settings ();
            });
        }

        private void build_ui () {
            content = new Gtk.Stack ();
            content.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

            headerbar = new Gtk.HeaderBar ();
            headerbar.show_close_button = true;
            headerbar.title = _("Play My Videos");

            //SETTINGS MENU
            var app_menu = new Gtk.MenuButton ();
            app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));

            var settings_menu = new Gtk.Menu ();

            var menu_item_library = new Gtk.MenuItem.with_label(_("Change Video Folder…"));
            menu_item_library.activate.connect (() => {
                var folder = library_manager.choose_folder ();
                if(folder != null) {
                    settings.library_location = folder;
                    library_manager.scan_local_library (folder);
                }
            });

            var menu_item_import = new Gtk.MenuItem.with_label (_("Import Videos…"));
            menu_item_import.activate.connect (() => {
                var folder = library_manager.choose_folder ();
                if(folder != null) {
                    library_manager.scan_local_library (folder);
                }
            });

            var menu_item_rescan = new Gtk.MenuItem.with_label (_("Rescan Library"));
            menu_item_rescan.activate.connect (() => {
                reset_all_views ();
                library_manager.rescan_library ();
            });

            settings_menu.append (menu_item_library);
            settings_menu.append (menu_item_import);
            settings_menu.append (new Gtk.SeparatorMenuItem ());
            settings_menu.append (menu_item_rescan);
            settings_menu.show_all ();

            app_menu.popup = settings_menu;
            headerbar.pack_end (app_menu);

            search_entry = new Gtk.SearchEntry ();
            search_entry.placeholder_text = _("Search Videos");
            search_entry.search_changed.connect (() => {
                boxes_view.filter = search_entry.text;
            });

            navigation_button = new Gtk.Button ();
            navigation_button.label = _("Library");
            navigation_button.valign = Gtk.Align.CENTER;
            navigation_button.can_focus = false;
            navigation_button.get_style_context ().add_class ("back-button");
            navigation_button.clicked.connect (show_boxes);

            headerbar.pack_start (navigation_button);
            headerbar.pack_end (search_entry);
            this.set_titlebar (headerbar);

            boxes_view = new Widgets.Views.BoxesView ();
            boxes_view.video_selected.connect (show_player);

            player_view = new Widgets.Views.PlayerView ();
            player_view.ended.connect (show_boxes);
            player_view.started.connect ((video) => {
                headerbar.title = video.title;
            });
            player_view.player_frame_resized.connect ((width, height) => {

                var current_width = this.get_allocated_width ();
                double w_r = (double)(current_width - 156) / width;
                int new_height = (int)(height * w_r) + 206;

                if (current_width <= 0 || new_height <=0) {
                    return;
                }

                this.get_window ().resize (current_width, new_height);
            });

            content.add_named (boxes_view, "boxes");
            content.add_named (player_view, "player");
            this.add (content);
            this.show_all ();

            navigation_button.hide ();
        }

        private void show_player (Objects.Video video) {
            content.set_visible_child_name ("player");
            navigation_button.show ();
            player_view.play (video);
            search_entry.hide ();
            hide_mouse_cursor ();
        }

        public void show_boxes () {
            content.set_visible_child_name ("boxes");
            player_view.pause ();
            navigation_button.hide ();
            headerbar.title = _("Play My Videos");
            search_entry.show ();
            this.get_window ().resize (settings.window_width, settings.window_height);
        }

        private void load_settings () {
            if (settings.window_maximized) {
                this.maximize ();
                this.set_default_size (1024, 720);
            } else {
                this.set_default_size (settings.window_width, settings.window_height);
            }
        }

        private void save_settings () {
            settings.window_maximized = this.is_maximized;
        }

        public void search () {
            this.search_entry.grab_focus ();
        }

        public void search_reset () {
            if (this.search_entry.text != "") {
                this.search_entry.text = "";
            } else {
                boxes_view.unselect_all ();
            }
        }

        private void reset_all_views () {
            player_view.reset ();
            boxes_view.reset ();
        }

        private async void load_content_from_database () {
            foreach (var box in library_manager.boxes) {
                boxes_view.add_box (box);
            }
        }

        public void hide_mouse_cursor () {
            var display = this.get_window ().get_display ();
            var cursor = new Gdk.Cursor.for_display (display, Gdk.CursorType.BLANK_CURSOR);
            this.get_window ().set_cursor (cursor);
        }

        public void show_mouse_cursor () {
            this.get_window ().set_cursor (null);
        }

        public void open_file (File file) {
            if (!boxes_view.open_file (file)) {
                var ext_video = new Objects.Video ();
                ext_video.path = file.get_path ();
                show_player (ext_video);
            }
        }
    }
}
