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

namespace PlayMyVideos {
    public class MainWindow : Gtk.Window {
        Services.LibraryManager library_manager;
        Settings settings;

        Gdk.WindowState current_state;

        Gtk.HeaderBar headerbar;
        Gtk.SearchEntry search_entry;
        Gtk.Spinner spinner;
        Gtk.Stack content;
        Gtk.Button navigation_button;
        Gtk.Button play_button;
        Gtk.MenuButton app_menu;
        Gtk.MenuItem menu_item_rescan;
        Widgets.Views.BoxesView boxes_view;
        Widgets.Views.PlayerView player_view;

        const Gtk.TargetEntry[] targets = {
            {"text/uri-list",0,0}
        };

        construct {
            settings = Settings.get_default ();
            settings.notify["use-dark-theme"].connect (
                () => {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.use_dark_theme;
                    if (settings.use_dark_theme) {
                        app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
                    } else {
                        app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
                    }
                });

            library_manager = PlayMyVideos.Services.LibraryManager.instance;
            library_manager.added_new_box.connect (
                (box) => {
                    Idle.add (
                        () => {
                            if (content.visible_child_name == "welcome") {
                                content.visible_child_name = "boxes";
                            }
                            return false;
                        });
                });
            library_manager.sync_started.connect (
                () => {
                    Idle.add (
                        () => {
                            spinner.active = true;
                            menu_item_rescan.sensitive = false;
                            search_entry.text = "";
                            return false;
                        });
                });
            library_manager.sync_finished.connect (
                () => {
                    Idle.add (
                        () => {
                            spinner.active = false;
                            menu_item_rescan.sensitive = true;
                            return false;
                        });
                });

            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, targets, Gdk.DragAction.LINK);

            this.drag_motion.connect (
                (context, x, y, time) => {
                    Gtk.drag_unhighlight (this);
                    return true;
                });

            this.drag_data_received.connect (
                (drag_context, x, y, data, info, time) => {
                    foreach (var uri in data.get_uris ()) {
                        var file = File.new_for_uri (uri);
                        try {
                            var file_info = file.query_info ("standard::*", GLib.FileQueryInfoFlags.NONE);

                            if (file_info.get_file_type () == FileType.DIRECTORY) {
                                library_manager.scan_local_library_for_new_files (file.get_path ());
                                continue;
                            }

                            string mime_type = file_info.get_content_type ();
                            if (mime_type.has_prefix ("video/")) {
                                library_manager.found_local_video_file (file.get_path (), mime_type);
                            }
                        } catch (Error err) {
                            warning (err.message);
                        }
                    }
                });
        }

        public MainWindow () {
            this.events |= Gdk.EventMask.POINTER_MOTION_MASK;

            load_settings ();
            build_ui ();

            load_content_from_database.begin (
                (obj, res) => {
                    library_manager.sync_library_content.begin ();
                    visible_playing_button ();
                });
            this.motion_notify_event.connect (
                (event) => {
                    show_mouse_cursor ();
                    return false;
                });
            this.window_state_event.connect (
                (event) => {
                    current_state = event.new_window_state;
                    return false;
                });
            this.delete_event.connect (
                () => {
                    save_settings ();
                    player_view.reset ();
                    return false;
                });
            this.key_press_event.connect (
                (key) => {
                    if (content.visible_child_name == "player") {
                        switch (key.keyval) {
                        case Gdk.Key.Left :
                            if (Gdk.ModifierType.MOD1_MASK in key.state) {
                                break;
                            }
                            if (Gdk.ModifierType.SHIFT_MASK in key.state) {
                                seek_seconds (-300);
                            } else {
                                seek_seconds (-10);
                            }
                            return true;
                        case Gdk.Key.Right :
                            if (Gdk.ModifierType.MOD1_MASK in key.state) {
                                break;
                            }
                            if (Gdk.ModifierType.SHIFT_MASK in key.state) {
                                seek_seconds (300);
                            } else {
                                seek_seconds (10);
                            }
                            return true;
                        case Gdk.Key.space :
                            toggle_playing ();
                            return true;
                        }
                    } else if (!search_entry.is_focus && key.str.strip ().length > 0) {
                        search_entry.grab_focus ();
                    }
                    return false;
                });
        }

        private void build_ui () {
            content = new Gtk.Stack ();
            content.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

            headerbar = new Gtk.HeaderBar ();
            headerbar.show_close_button = true;
            headerbar.get_style_context ().add_class ("default-decoration");
            headerbar.title = _ ("Cinema");

            play_button = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            play_button.valign = Gtk.Align.CENTER;
            play_button.tooltip_text = _ ("Resume playing");
            play_button.clicked.connect (
                () => {
                    toggle_playing ();
                });

            headerbar.pack_start (play_button);

            //SETTINGS MENU
            app_menu = new Gtk.MenuButton ();
            if (settings.use_dark_theme) {
                app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            } else {
                app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
            }

            var settings_menu = new Gtk.Menu ();

            var menu_item_library = new Gtk.MenuItem.with_label (_ ("Change Video Folder…"));
            menu_item_library.activate.connect (
                () => {
                    var folder = library_manager.choose_folder ();
                    if (folder != null) {
                        settings.library_location = folder;
                        library_manager.scan_local_library_for_new_files (folder);
                    }
                });

            var menu_item_import = new Gtk.MenuItem.with_label (_ ("Import Videos…"));
            menu_item_import.activate.connect (
                () => {
                    var folder = library_manager.choose_folder ();
                    if (folder != null) {
                        library_manager.scan_local_library_for_new_files (folder);
                    }
                });

            menu_item_rescan = new Gtk.MenuItem.with_label (_ ("Rescan Library"));
            menu_item_rescan.activate.connect (
                () => {
                    reset_all_views ();
                    library_manager.rescan_library ();
                });

            var menu_item_preferences = new Gtk.MenuItem.with_label (_ ("Preferences"));
            menu_item_preferences.activate.connect (
                () => {
                    var preferences = new Dialogs.Preferences (this);
                    preferences.run ();
                });

            settings_menu.append (menu_item_library);
            settings_menu.append (menu_item_import);
            settings_menu.append (new Gtk.SeparatorMenuItem ());
            settings_menu.append (menu_item_rescan);
            settings_menu.append (new Gtk.SeparatorMenuItem ());
            settings_menu.append (menu_item_preferences);
            settings_menu.show_all ();

            app_menu.popup = settings_menu;
            headerbar.pack_end (app_menu);

            search_entry = new Gtk.SearchEntry ();
            search_entry.placeholder_text = _ ("Search Videos");
            search_entry.valign = Gtk.Align.CENTER;
            search_entry.search_changed.connect (
                () => {
                    boxes_view.filter = search_entry.text;
                });
            headerbar.pack_end (search_entry);

            // SPINNER
            spinner = new Gtk.Spinner ();
            headerbar.pack_end (spinner);

            navigation_button = new Gtk.Button ();
            navigation_button.label = _ ("Back");
            navigation_button.valign = Gtk.Align.CENTER;
            navigation_button.can_focus = false;
            navigation_button.get_style_context ().add_class ("back-button");
            navigation_button.clicked.connect (
                () => {
                    settings.last_played_video_progress = player_view.playback.progress;
                    show_boxes ();
                    player_view.clear_last_size ();
                });

            headerbar.pack_start (navigation_button);

            this.set_titlebar (headerbar);

            boxes_view = new Widgets.Views.BoxesView ();
            boxes_view.video_selected.connect (show_player);

            player_view = new Widgets.Views.PlayerView ();
            player_view.ended.connect (
                () => {
                    settings.last_played_video_uri = "";
                    settings.last_played_video_progress = 0;
                    show_boxes ();
                });
            player_view.started.connect (
                (video) => {
                    headerbar.title = video.title;
                    play_button.visible = false;
                });
            player_view.player_frame_resized.connect (
                (width, height) => {
                    if (width < 0 || height < 0) {
                        return;
                    }
                    var current_width = this.get_allocated_width ();
                    double w_r = (double)(current_width - 156) / width;
                    int new_height = (int)(height * w_r) + 193;
                    if (current_width <= 0 || new_height <=0) {
                        return;
                    }
                    this.get_window ().resize (current_width, new_height);
                });

            var welcome = new Widgets.Views.Welcome ();

            content.add_named (welcome, "welcome");
            content.add_named (boxes_view, "boxes");
            content.add_named (player_view, "player");
            this.add (content);
            this.show_all ();
            navigation_button.hide ();
        }

        private void visible_playing_button () {
            if (settings.last_played_video_uri != "" && content.visible_child_name != "player") {
                var f = File.new_for_uri (settings.last_played_video_uri);
                if (f.query_exists ()) {
                    play_button.visible = f.query_exists ();
                    boxes_view.select_file (f);
                } else {
                    play_button.visible = false;
                }
            } else {
                play_button.visible = false;
            }
        }

        private void resume_playing () {
            content.visible_child_name = "player";
            navigation_button.show ();
            search_entry.hide ();
            hide_mouse_cursor ();
            player_view.toogle_playing ();
        }

        private void show_player (Objects.Video video) {
            content.visible_child_name = "player";
            navigation_button.show ();
            player_view.play (video);
            search_entry.hide ();
            hide_mouse_cursor ();
        }

        public void show_boxes () {
            this.unfullscreen ();
            if (boxes_view.has_items) {
                content.visible_child_name = "boxes";
                search_entry.show ();
            } else {
                content.visible_child_name = "welcome";
            }
            visible_playing_button ();
            player_view.pause ();
            navigation_button.hide ();
            headerbar.title = _ ("Cinema");
            this.get_window ().resize (settings.window_width, settings.window_height);
        }

        private void load_settings () {
            if (settings.window_maximized) {
                this.maximize ();
                this.set_default_size (1024, 720);
            } else {
                this.set_default_size (settings.window_width, settings.window_height);
            }

            if (settings.window_x < 0 || settings.window_y < 0 ) {
                this.window_position = Gtk.WindowPosition.CENTER;
            } else {
                this.move (settings.window_x, settings.window_y);
            }
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.use_dark_theme;
        }

        private void save_settings () {
            settings.window_maximized = this.is_maximized;
            if (settings.last_played_video_uri != "") {
                settings.last_played_video_progress = player_view.playback.progress;
            } else {
                settings.last_played_video_progress = 0;
            }

            if (!settings.window_maximized) {
                int x, y;
                this.get_position (out x, out y);
                settings.window_x = x;
                settings.window_y = y;

                int width, height;
                this.get_size (out width, out height);
                settings.window_height = height;
                settings.window_width = width;
            }
        }

        public void search_reset () {
            if (content.visible_child_name == "player") {
                this.unfullscreen ();
            } else if (this.search_entry.text != "") {
                search_entry.text = "";
            } else {
                boxes_view.unselect_all ();
            }
        }

        public void pause () {
            if (content.visible_child_name == "player") {
                player_view.playback.playing = false;
            }
        }

        public void next () {
            if (content.visible_child_name == "player") {
                player_view.next ();
            }
        }

        public void toggle_playing () {
            if (content.visible_child_name == "player") {
                player_view.toogle_playing ();
            } else {
                if (player_view.playback.uri == settings.last_played_video_uri) {
                    resume_playing ();
                    player_view.playback.progress = settings.last_played_video_progress;
                } else {
                    var f = File.new_for_uri (settings.last_played_video_uri);
                    open_file (f);
                    player_view.playback.progress = settings.last_played_video_progress;
                }
            }
        }

        public void toggle_fullscreen () {
            if (content.visible_child_name != "player") {
                return;
            }
            // FIXME: doesn't work without .to_string ()
            if (current_state.to_string () == Gdk.WindowState.FULLSCREEN.to_string ()) {
                this.unfullscreen ();
            } else {
                this.fullscreen ();
            }
        }

        public void seek_seconds (int seconds) {
            if (content.visible_child_name == "player") {
                player_view.seek_seconds (seconds);
            }
        }

        private void reset_all_views () {
            player_view.reset ();
            boxes_view.reset ();
            settings.last_played_video_progress = 0;
            settings.last_played_video_uri = "";
            visible_playing_button ();
            content.visible_child_name = "welcome";
        }

        private async void load_content_from_database () {
            foreach (var box in library_manager.boxes) {
                boxes_view.add_box (box);
                if (content.visible_child_name == "welcome") {
                    content.visible_child_name = "boxes";
                }
            }
        }

        public void hide_mouse_cursor () {
            var cursor = new Gdk.Cursor.from_name (Gdk.Display.get_default (), "none");
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

        public void open_files (File[] files) {
            if (files.length == 1 && files[0].query_exists ()) {
                open_file (files[0]);
            } else {
                var ext_box  = new Objects.Box ();
                for (int i = 0; i<files.length; i++) {
                    if (files[i].query_exists ()) {
                        var ext_video = new Objects.Video (ext_box);
                        ext_video.ID = i;
                        ext_video.path = files[i].get_path ();
                        ext_box.add_video (ext_video);
                    }
                }

                if (ext_box.videos.length ()>0) {
                    show_player (ext_box.get_first_video ());
                }
            }
        }
    }
}
