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
        public string title { get; set; }
        public int year { get; set; default = 0; }

        public signal void thumbnail_normal_changed ();

        string thumbnail_large_path;
        string thumbnail_normal_path;

        string _path;
        public string path {
            get {
                return _path;
            } set {
                _path = value;

                var file = File.new_for_path (_path);
                _uri = file.get_uri ();

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
                        create_thumbnail_normal ();
                    }
                }
                return _thumbnail_normal;
            }
        }

        Box? _box = null;
        public Box box {
            get {
                return _box;
            }
        }

        construct {
            library_manager = PlayMyVideos.Services.LibraryManager.instance;
        }

        public Video (Box? box = null) {
            this._box = box;
        }

        public void set_box (Box box) {
            this._box = box;
        }

        private void create_thumbnail_normal () {
            if (mime_type == "" || _thumbnail_normal != null) {
                return;
            }
            new Thread<void*> (null, () => {
                var file = File.new_for_path (thumbnail_normal_path);
                if (!file.query_exists ()) {
                    Interfaces.DbusThumbnailer.instance.finished.connect (thumbnail_finished);
                    Gee.ArrayList<string> uris = new Gee.ArrayList<string> ();
                    Gee.ArrayList<string> mimes = new Gee.ArrayList<string> ();

                    file = File.new_for_path (path);
                    uris.add (file.get_uri ());
                    mimes.add (mime_type);

                    Interfaces.DbusThumbnailer.instance.create_thumbnails (uris, mimes, "normal");
                }
                return null;
            });
        }


        private void thumbnail_finished () {
            var file = File.new_for_path (thumbnail_normal_path);
            if (file.query_exists ()) {
                Interfaces.DbusThumbnailer.instance.finished.disconnect (thumbnail_finished);
                thumbnail_normal_changed ();
            }
        }
    }
}
