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

namespace PlayMyVideos.Dialogs {
    public class Preferences : Gtk.Dialog {
        Settings settings;

        construct {
            settings = PlayMyVideos.Settings.get_default ();
        }

        public Preferences (Gtk.Window parent) {
            Object (
                transient_for: parent,
                deletable: false,
                resizable: false
            );
            build_ui ();

            this.response.connect ((source, response_id) => {
                switch (response_id) {
                    case Gtk.ResponseType.CLOSE:
                        destroy ();
                    break;
                }
            });
        }

        private void build_ui () {
            var content = get_content_area () as Gtk.Box;

            var grid = new Gtk.Grid ();
            grid.column_spacing = 12;
            grid.row_spacing = 12;
            grid.margin = 12;

            var load_content_label = new Gtk.Label (_("Load Content from The Movie DB"));
            load_content_label.halign = Gtk.Align.START;
            var load_content = new Gtk.Switch ();
            load_content.active = settings.load_content_from_moviedb;
            load_content.notify["active"].connect (() => {
                settings.load_content_from_moviedb = load_content.active;
            });

            var save_custom_covers_label = new Gtk.Label (_("Save custom Covers in Library folder"));
            save_custom_covers_label.halign = Gtk.Align.START;
            var save_custom_covers = new Gtk.Switch ();
            save_custom_covers.active = settings.save_custom_covers;
            save_custom_covers.notify["active"].connect (() => {
                settings.save_custom_covers = save_custom_covers.active;
            });

            grid.attach (load_content_label, 0, 0);
            grid.attach (load_content, 1, 0);
            grid.attach (save_custom_covers_label, 0, 1);
            grid.attach (save_custom_covers, 1, 1);

            content.pack_start (grid, false, false, 0);

            this.add_button (_("_Close"), Gtk.ResponseType.CLOSE);
            this.show_all ();
        }
    }
}
