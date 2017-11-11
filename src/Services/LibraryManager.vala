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

namespace PlayMyVideos.Services {
    public class LibraryManager : GLib.Object {
        PlayMyVideos.Settings settings;

        static LibraryManager _instance = null;
        public static LibraryManager instance {
            get {
                if (_instance == null) {
                    _instance = new LibraryManager ();
                }
                return _instance;
            }
        }

        public signal void added_new_box (PlayMyVideos.Objects.Box box);

        public PlayMyVideos.Services.DataBaseManager db_manager { get; construct set; }
        public PlayMyVideos.Services.LocalFilesManager lf_manager { get; construct set; }

        public GLib.List<PlayMyVideos.Objects.Box> boxes {
            get {
                return db_manager.boxes;
            }
        }

        construct {
            settings = PlayMyVideos.Settings.get_default ();

            lf_manager = PlayMyVideos.Services.LocalFilesManager.instance;
            lf_manager.found_video_file.connect (found_local_video_file);

            db_manager = PlayMyVideos.Services.DataBaseManager.instance;
            db_manager.added_new_box.connect ((box) => { added_new_box (box); });
        }

        private LibraryManager () { }

        public void reset_library () {
            db_manager.reset_database ();
            File directory = File.new_for_path (PlayMyVideos.PlayMyVideosApp.instance.COVER_FOLDER);
            try {
                var children = directory.enumerate_children ("", 0);
                FileInfo file_info;
                while ((file_info = children.next_file ()) != null) {
                     var file = File.new_for_path (GLib.Path.build_filename (PlayMyVideos.PlayMyVideosApp.instance.COVER_FOLDER, file_info.get_name ()));
                     file.delete ();
                     file.dispose ();
                }
                children.close ();
                children.dispose ();
            } catch (Error err) {
                warning (err.message);
            }
            directory.dispose ();
        }

        public void rescan_library () {
            reset_library ();
            scan_local_library (settings.library_location);
        }

        // LOCAL FILES REGION
        public void scan_local_library (string path) {
            lf_manager.scan (path);
        }

        public void found_local_video_file (string path, string mime_type) {
            new Thread<void*> (null, () => {
                if (!db_manager.video_file_exists (path)) {
                    insert_video_file (path, mime_type);
                }
                return null;
            });
        }

        private void insert_video_file (string path, string mime_type) {
            var box = new Objects.Box (Path.get_basename (Path.get_dirname (path)));
            var db_box = db_manager.insert_box_if_not_exists (box);
            var video = new Objects.Video ();
            video.path = path;
            video.mime_type = mime_type;

            db_box.add_video_if_not_exists (video);
        }

        //PIXBUF
        public string? choose_new_cover () {
            string? return_value = null;
            var cover = new Gtk.FileChooserDialog (
                _("Choose an image…"), PlayMyVideosApp.instance.mainwindow,
                Gtk.FileChooserAction.OPEN,
                _("_Cancel"), Gtk.ResponseType.CANCEL,
                _("_Open"), Gtk.ResponseType.ACCEPT);

            var filter = new Gtk.FileFilter ();
            filter.set_filter_name (_("Images"));
            filter.add_mime_type ("image/*");

            cover.add_filter (filter);

            if (cover.run () == Gtk.ResponseType.ACCEPT) {
                return_value = cover.get_filename ();
            }

            cover.destroy();
            return return_value;
        }

        public string? choose_folder () {
            string? return_value = null;
            Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
                _("Select a folder."), PlayMyVideosApp.instance.mainwindow, Gtk.FileChooserAction.SELECT_FOLDER,
                _("_Cancel"), Gtk.ResponseType.CANCEL,
                _("_Open"), Gtk.ResponseType.ACCEPT);

            var filter = new Gtk.FileFilter ();
            filter.set_filter_name (_("Folder"));
            filter.add_mime_type ("inode/directory");

            chooser.add_filter (filter);

            if (chooser.run () == Gtk.ResponseType.ACCEPT) {
                return_value = chooser.get_file ().get_path ();
            }

            chooser.destroy ();
            return return_value;
        }
    }
}
