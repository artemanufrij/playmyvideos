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

namespace PlayMyVideos.Objects {
    public class Video : GLib.Object {
        PlayMyVideos.Services.LibraryManager library_manager;

        public int ID { get; set; }
        public string title { get; private set; }
        public int year { get; private set; default = 0; }

        public signal void thumbnail_normal_changed ();
        public signal void thumbnail_large_changed ();

        string thumbnail_large_path;
        string thumbnail_normal_path;

        string _path = "";
        public string path {
            get {
                return _path;
            } set {
                _path = value;

                var file = File.new_for_path (_path);
                _uri = file.get_uri ();
                title = Utils.get_title_from_basename (file.get_basename ());
                year = Utils.get_year_from_basename (file.get_basename ());
                file.dispose ();

                var hash_file_poster = GLib.Checksum.compute_for_string (ChecksumType.MD5, file.get_uri (), file.get_uri ().length);

                thumbnail_large_path = Path.build_filename (GLib.Environment.get_user_cache_dir (),"thumbnails", "large", hash_file_poster + ".png");
                thumbnail_normal_path = Path.build_filename (GLib.Environment.get_user_cache_dir (),"thumbnails", "normal", hash_file_poster + ".png");
            }
        }

        string _uri = "";
        public string uri {
            get {
                return _uri;
            } set {
                _uri = value;
            }
        }

        string _mime_type = "";
        public string mime_type {
            get {
                return _mime_type;
            } set {
                _mime_type = value;
            }
        }

        GLib.List<string> _local_subtitles = null;
        public GLib.List<string> local_subtitles {
            get {
                if (_local_subtitles == null) {
                    _local_subtitles = new GLib.List<string> ();
                    var directory = File.new_for_path (this.path).get_parent ();
                    if (directory != null) {
                        try {
                            var children = directory.enumerate_children (FileAttribute.STANDARD_CONTENT_TYPE , GLib.FileQueryInfoFlags.NONE);
                            FileInfo file_info;
                            while ((file_info = children.next_file ()) != null) {
                                foreach (var ext in Utils.subtitle_extentions ()) {
                                    if (file_info.get_name ().has_suffix (ext)) {
                                        _local_subtitles.append (file_info.get_name ());
                                        break;
                                    }
                                }
                            }
                        } catch (Error err) {
                            warning (err.message);
                        }
                        directory.dispose ();
                    }
                }
                return _local_subtitles;
            }
        }

        Gdk.Pixbuf? _thumbnail_normal = null;
        public Gdk.Pixbuf? thumbnail_normal {
            get {
                if (_thumbnail_normal == null) {
                    var file = File.new_for_path (thumbnail_normal_path);
                    if (file.query_exists ()) {
                        Gdk.Pixbuf pixbuf = null;
                        try {
                            pixbuf = new Gdk.Pixbuf.from_file (thumbnail_normal_path);
                        } catch (Error err) {
                            warning (err.message);
                        }
                        if (pixbuf != null) {
                         _thumbnail_normal = PlayMyVideos.Utils.align_pixbuf_for_thumbnail_normal (pixbuf);
                        }
                    } else {
                        create_thumbnail.begin ("normal");
                    }
                    file.dispose ();
                }
                return _thumbnail_normal;
            }
        }

        Gdk.Pixbuf? _thumbnail_large = null;
        public Gdk.Pixbuf? thumbnail_large {
            get {
                if (_thumbnail_large == null) {
                    var file = File.new_for_path (thumbnail_large_path);
                    if (file.query_exists ()) {
                        try {
                            _thumbnail_large = new Gdk.Pixbuf.from_file (thumbnail_large_path);
                        } catch (Error err) {
                            warning (err.message);
                        }
                    } else {
                        create_thumbnail.begin ("large");
                    }
                    file.dispose ();
                }
                return _thumbnail_large;
            }
        }


        public Box? box { get; set; default = null; }

        construct {
            library_manager = PlayMyVideos.Services.LibraryManager.instance;
        }

        public Video (Box? box = null) {
            this.box = box;
        }

        public bool file_exists () {
            var file = File.new_for_uri (this.uri);
            bool return_value = file.query_exists ();
            file.dispose ();
            return return_value;
        }

        private async void create_thumbnail (string size) {
            if (size == "normal" && (mime_type == "" || _thumbnail_normal != null)) {
                return;
            } else if (size == "large" && (mime_type == "" || _thumbnail_large != null)) {
                return;
            }

            File? file = null;
            if (size == "normal") {
                file = File.new_for_path (thumbnail_normal_path);
            } else if (size == "large") {
                file = File.new_for_path (thumbnail_large_path);
            }
            if (file != null && !file.query_exists ()) {
                if (size == "normal") {
                    Interfaces.DbusThumbnailer.instance.finished.connect (thumbnail_finished_normal);
                } else if (size == "large") {
                    Interfaces.DbusThumbnailer.instance.finished.connect (thumbnail_finished_large);
                }
                Gee.ArrayList<string> uris = new Gee.ArrayList<string> ();
                Gee.ArrayList<string> mimes = new Gee.ArrayList<string> ();

                file = File.new_for_path (path);
                uris.add (file.get_uri ());
                mimes.add (mime_type);

                file.dispose ();

                Interfaces.DbusThumbnailer.instance.create_thumbnails (uris, mimes, size);
            }
        }

        private void thumbnail_finished_large () {
            var file = File.new_for_path (thumbnail_large_path);
            if (file.query_exists ()) {
                Interfaces.DbusThumbnailer.instance.finished.disconnect (thumbnail_finished_large);
                thumbnail_large_changed ();
            }
            file.dispose ();
        }

        private void thumbnail_finished_normal () {
            var file = File.new_for_path (thumbnail_normal_path);
            if (file.query_exists ()) {
                Interfaces.DbusThumbnailer.instance.finished.disconnect (thumbnail_finished_normal);
                thumbnail_normal_changed ();
            }
            file.dispose ();
        }
    }
}
