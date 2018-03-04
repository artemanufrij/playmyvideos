/*-
 * Copyright (c) 2018-2018 Artem Anufrij <artem.anufrij@live.de>
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
    public class MovieDatabaseManager {
        static MovieDatabaseManager _instance = null;
        public static MovieDatabaseManager instance {
            get {
                if (_instance == null) {
                    _instance = new MovieDatabaseManager ();
                }
                return _instance;
            }
        }

        private string key = "3f3692d9c336994625a838a95b9a2ed0";

        GLib.List<Objects.Box> boxes = new GLib.List<Objects.Box> ();

        bool box_thread_running = false;

        private MovieDatabaseManager () {
        }

        public void fill_box_cover_queue (Objects.Box box) {
            lock (boxes) {
                if (boxes.index (box) == -1) {
                    boxes.append (box);
                }
            }
            read_box_queue ();
        }

        private void read_box_queue () {
            if (box_thread_running) {
                return;
            }
            box_thread_running = true;

            new Thread<void*> (
                "read_box_queue",
                () => {
                    Objects.Box ? first = null;

                    while (boxes.length () > 0) {
                        lock (boxes) {
                            first = boxes.first ().data;
                            if (first == null) {
                                continue;
                            }
                            boxes.remove (first);
                        }
                        Thread.usleep (1000000);

                        string title;
                        int season;
                        int year;

                        Utils.get_title_items (first.title, out title, out season, out year);

                        if (year == 0) {
                            var video = first.get_first_video ();
                            if (video != null && video.year > 0) {
                                year = video.year;
                            }
                        }

                        Gdk.Pixbuf ? pixbuf = null;
                        if (season > 0) {
                            pixbuf = get_pixbuf_by_season_number (title, season);
                        } else {
                            pixbuf = get_pixbuf_by_movie_title (title, year);
                        }
                        if (pixbuf != null) {
                            pixbuf = Utils.align_and_scale_pixbuf_for_cover (pixbuf);
                            try {
                                if (pixbuf.save (first.cover_path, "jpeg", "quality", "100")) {
                                    if (Settings.get_default ().save_custom_covers) {
                                        first.set_custom_cover_file (first.cover_path);
                                    }
                                    first.load_cover_async.begin ();
                                }
                            } catch (Error err) {
                                warning (err.message);
                            }
                        }
                    }

                    box_thread_running = false;
                    return null;
                });
        }

        private Gdk.Pixbuf ? get_pixbuf_by_season_number (string title, int season) {
            string url = "https://api.themoviedb.org/3/search/tv?api_key=%s&query=%s&page=1".printf (key, title);
            var body = get_body_from_url (url);
            if (body != null) {
                var tv_id = Utils.get_tv_id (body);
                if (tv_id != null && tv_id > 0) {
                    return get_pixbuf_by_tv_id (tv_id, season);
                }
            }
            return null;
        }

        private Gdk.Pixbuf ? get_pixbuf_by_tv_id (int tv_id, int season) {
            string url = "https://api.themoviedb.org/3/tv/%d/season/%d?api_key=%s".printf (tv_id, season, key);
            var body = get_body_from_url (url);
            if (body != null) {
                var img_path = Utils.get_poster_path (body);
                if (img_path != null) {
                    return get_pixbuf_from_url (img_path);
                }
            }
            return null;
        }

        private Gdk.Pixbuf ? get_pixbuf_by_movie_title (string title, int year = 0) {
            string url = "https://api.themoviedb.org/3/search/movie?api_key=%s&query=%s&page=1&include_adult=false".printf (key, title);
            if (year > 0) {
                url = "https://api.themoviedb.org/3/search/movie?api_key=%s&query=%s&page=1&primary_release_year=%d&include_adult=false".printf (key, title, year);
            }

            stdout.printf ("%s\n", url);

            var body = get_body_from_url (url);
            if (body != null) {
                var img_path = Utils.get_poster_path (body);
                if (img_path != null) {
                    return get_pixbuf_from_url (img_path);
                }
            }
            return null;
        }

        private string ? get_body_from_url (string url) {
            stdout.printf ("%s\n", url);
            string ? return_value = null;
            var session = new Soup.Session.with_options ("user_agent", "PlayMyVideos/0.1.0 (https://github.com/artemanufrij/playmyvideos)");
            var msg = new Soup.Message ("GET", url);
            session.send_message (msg);
            if (msg.status_code == 200) {
                return_value = (string)msg.response_body.data;
            }
            msg.dispose ();
            session.dispose ();
            return return_value;
        }

        public Gdk.Pixbuf ? get_pixbuf_from_url (string url) {
            if (!url.has_prefix ("http")) {
                return null;
            }
            Gdk.Pixbuf ? return_value = null;
            var session = new Soup.Session.with_options ("user_agent", "PlayMyVideos/0.1.0 (https://github.com/artemanufrij/playmyvideos)");
            var msg = new Soup.Message ("GET", url);
            session.send_message (msg);
            if (msg.status_code == 200) {
                string tmp_file = GLib.Path.build_filename (GLib.Environment.get_user_cache_dir (), Random.next_int ().to_string () + ".jpg");
                var fs = FileStream.open (tmp_file, "w");
                fs.write (msg.response_body.data, (size_t)msg.response_body.length);
                try {
                    return_value = new Gdk.Pixbuf.from_file (tmp_file);
                } catch (Error err) {
                                warning (err.message);
                }
                File f = File.new_for_path (tmp_file);
                f.delete_async.begin ();
            }
            msg.dispose ();
            session.dispose ();
            return return_value;
        }
    }
}