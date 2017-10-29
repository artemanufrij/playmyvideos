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

        Widgets.Views.BoxesView boxes_view;
        Widgets.Views.PlayerView player_view;

        construct {
            settings = PlayMyVideos.Settings.get_default ();

            library_manager = PlayMyVideos.Services.LibraryManager.instance;
        }

        public MainWindow () {
            load_settings ();
            this.window_position = Gtk.WindowPosition.CENTER;
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
            build_ui ();

            load_content_from_database.begin ((obj, res) => {
                library_manager.scan_local_library (settings.library_location);
            });
            this.configure_event.connect ((event) => {
                settings.window_width = event.width;
                settings.window_height = event.height;
                return false;
            });

            this.destroy.connect (() => {
                save_settings ();
            });
        }

        private void build_ui () {
            this.title = "Video Player";

            var content = new Gtk.Stack ();
            content.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

            boxes_view = new Widgets.Views.BoxesView ();
            boxes_view.video_selected.connect ((video) => {
                content.set_visible_child_name ("player");
                player_view.play (video);
            });

            player_view = new Widgets.Views.PlayerView ();
            player_view.player_frame_resized.connect ((width, height) => {
                stdout.printf ("%d, %d\n", width, height);
            });

            content.add_named (boxes_view, "boxes");
            content.add_named (player_view, "player");
            this.add (content);
            this.show_all ();
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

        private async void load_content_from_database () {
            foreach (var box in library_manager.boxes) {
                boxes_view.add_box (box);
            }
        }
    }
}
