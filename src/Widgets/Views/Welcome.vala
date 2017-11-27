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
    public class Welcome : Gtk.Grid {
        PlayMyVideos.Services.LibraryManager library_manager;
        PlayMyVideos.Settings settings;

        construct {
            library_manager = PlayMyVideos.Services.LibraryManager.instance;
            settings = PlayMyVideos.Settings.get_default ();
        }

        public Welcome () {
            build_ui ();
        }

        private void build_ui () {
            var welcome = new Granite.Widgets.Welcome ("Get Some Videos", "Add videos to your library.");
            welcome.append ("folder-video", _("Change Video Folder"), _("Load videos from a folder, a network or an external disk."));
            welcome.append ("document-import", _("Import Videos"), _("Import videos from a source into your library."));
            welcome.activated.connect ((index) => {
                switch (index) {
                    case 0:
                        var folder = library_manager.choose_folder ();
                        if(folder != null) {
                            settings.library_location = folder;
                            library_manager.scan_local_library_for_new_files (folder);
                        }
                        break;
                    case 1:
                        var folder = library_manager.choose_folder ();
                        if(folder != null) {
                            library_manager.scan_local_library_for_new_files (folder);
                        }
                        break;
                }
            });

            this.add (welcome);
            this.show_all ();
        }
    }
}
