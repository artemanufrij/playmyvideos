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
    public class DataBaseManager : GLib.Object {
        static DataBaseManager _instance = null;
        public static DataBaseManager instance {
            get {
                if (_instance == null) {
                    _instance = new DataBaseManager ();
                }
                return _instance;
            }
        }

        public signal void added_new_box (PlayMyVideos.Objects.Box box);

        GLib.List<PlayMyVideos.Objects.Box> _boxes = null;
        public GLib.List<PlayMyVideos.Objects.Box> boxes {
            get {
                if (_boxes == null) {
                    _boxes = get_box_collection ();
                }
                return _boxes;
            }
        }

        Sqlite.Database db;
        string errormsg;

        construct {
        }

        private DataBaseManager () {
            open_database ();
        }

        private void open_database () {
            Sqlite.Database.open (PlayMyVideos.PlayMyVideosApp.instance.DB_PATH, out db);

            string q;

            q = """CREATE TABLE IF NOT EXISTS boxes (
                ID          INTEGER     PRIMARY KEY AUTOINCREMENT,
                title       TEXT        NOT NULL,
                year        INT         NULL,
                CONSTRAINT unique_album UNIQUE (title, year)
                );""";

            if (db.exec (q, null, out errormsg) != Sqlite.OK) {
                warning (errormsg);
            }

            q = """CREATE TABLE IF NOT EXISTS videos (
                ID          INTEGER     PRIMARY KEY AUTOINCREMENT,
                box_id      INT         NOT NULL,
                path        TEXT        NOT NULL,
                title       TEXT        NOT NULL,
                mime_type   TEXT        NOT NULL,
                CONSTRAINT unique_track UNIQUE (path),
                FOREIGN KEY (box_id) REFERENCES boxes (ID)
                    ON DELETE CASCADE
                );""";

            if (db.exec (q, null, out errormsg) != Sqlite.OK) {
                warning (errormsg);
            }

            q = """PRAGMA foreign_keys = ON;""";
            if (db.exec (q, null, out errormsg) != Sqlite.OK) {
                warning (errormsg);
            }
        }

        public void reset_database () {
            File db_path = File.new_for_path (PlayMyVideos.PlayMyVideosApp.instance.DB_PATH);
            try {
                db_path.delete ();
            } catch (Error err) {
                warning (err.message);
            }
            open_database ();
        }
// BOX REGION
        private GLib.List<PlayMyVideos.Objects.Box> get_box_collection () {
            GLib.List<PlayMyVideos.Objects.Box> return_value = new GLib.List<PlayMyVideos.Objects.Box> ();

            Sqlite.Statement stmt;
            string sql = """
                SELECT id, title FROM boxes ORDER BY title;
            """;

            db.prepare_v2 (sql, sql.length, out stmt);

            while (stmt.step () == Sqlite.ROW) {
                return_value.append (_fill_box (stmt));
            }
            stmt.reset ();

            return return_value;
        }

        public PlayMyVideos.Objects.Box _fill_box (Sqlite.Statement stmt) {
            PlayMyVideos.Objects.Box return_value = new PlayMyVideos.Objects.Box ();
            return_value.ID = stmt.column_int (0);
            return_value.title = stmt.column_text (1);
            return return_value;
        }

        public void insert_box (PlayMyVideos.Objects.Box box) {
            Sqlite.Statement stmt;
            string sql = """
                INSERT OR IGNORE INTO boxes (title) VALUES ($TITLE);
            """;

            db.prepare_v2 (sql, sql.length, out stmt);
            set_parameter_str (stmt, sql, "$TITLE", box.title);

            if (stmt.step () != Sqlite.DONE) {
                warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            }
            stmt.reset ();

            sql = """
                SELECT id FROM boxes WHERE title=$TITLE;
            """;

            db.prepare_v2 (sql, sql.length, out stmt);
            set_parameter_str (stmt, sql, "$TITLE", box.title);

            if (stmt.step () == Sqlite.ROW) {
                box.ID = stmt.column_int (0);
                stdout.printf ("Box ID: %d - %s\n", box.ID, box.title);
                _boxes.append (box);
                added_new_box (box);
            } else {
                warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            }
            stmt.reset ();
        }

        public PlayMyVideos.Objects.Box insert_box_if_not_exists (PlayMyVideos.Objects.Box new_box) {
            PlayMyVideos.Objects.Box? return_value = null;
            lock (_boxes) {
                foreach (var box in boxes) {
                    if (box.title == new_box.title) {
                        return_value = box;
                        break;
                    }
                }
                if (return_value == null) {
                    insert_box (new_box);
                    return_value = new_box;
                }
                return return_value;
            }
        }

// VIDEO REGION
        public GLib.List<PlayMyVideos.Objects.Video> get_video_collection (PlayMyVideos.Objects.Box box) {
            GLib.List<PlayMyVideos.Objects.Video> return_value = new GLib.List<PlayMyVideos.Objects.Video> ();
            Sqlite.Statement stmt;

            string sql = """
                SELECT id, title, path, mime_type
                FROM videos
                WHERE box_id=$BOX_ID
                ORDER BY title;
            """;

            db.prepare_v2 (sql, sql.length, out stmt);
            set_parameter_int (stmt, sql, "$BOX_ID", box.ID);

            while (stmt.step () == Sqlite.ROW) {
                return_value.append (_fill_video (stmt, box));
            }
            stmt.reset ();
            return return_value;
        }

        private PlayMyVideos.Objects.Video _fill_video (Sqlite.Statement stmt, PlayMyVideos.Objects.Box box) {
            PlayMyVideos.Objects.Video return_value = new PlayMyVideos.Objects.Video (box);
            return_value.ID = stmt.column_int (0);
            return_value.title = stmt.column_text (1);
            return_value.path = stmt.column_text (2);
            return_value.mime_type = stmt.column_text (3);
            return return_value;
        }

        public void insert_video (PlayMyVideos.Objects.Video video) {
            Sqlite.Statement stmt;

            string sql = """
                INSERT OR IGNORE INTO videos (box_id, title, path, mime_type) VALUES ($BOX_ID, $TITLE, $PATH, $MIME_TYPE);
            """;
            db.prepare_v2 (sql, sql.length, out stmt);
            set_parameter_int (stmt, sql, "$BOX_ID", video.box.ID);
            set_parameter_str (stmt, sql, "$TITLE", video.title);
            set_parameter_str (stmt, sql, "$PATH", video.path);
            set_parameter_str (stmt, sql, "$MIME_TYPE", video.mime_type);

            if (stmt.step () != Sqlite.DONE) {
                warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            }
            stmt.reset ();

            sql = """
                SELECT id FROM videos WHERE path=$PATH;
            """;

            db.prepare_v2 (sql, sql.length, out stmt);
            set_parameter_str (stmt, sql, "$PATH", video.path);

            if (stmt.step () == Sqlite.ROW) {
                video.ID = stmt.column_int (0);
                stdout.printf ("Video ID: %d - %s\n", video.ID, video.title);
            } else {
                warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            }
            stmt.reset ();
        }


// UTILITIES REGION
        public bool video_file_exists (string path) {
            bool file_exists = false;
            Sqlite.Statement stmt;

            string sql = """
                SELECT COUNT (*) FROM videos WHERE path=$PATH;
            """;

            db.prepare_v2 (sql, sql.length, out stmt);
            set_parameter_str (stmt, sql, "$PATH", path);

            if (stmt.step () == Sqlite.ROW) {
                file_exists = stmt.column_int (0) > 0;
            }
            stmt.reset ();
            return file_exists;
        }


// PARAMENTER REGION
        private void set_parameter_int (Sqlite.Statement? stmt, string sql, string par, int val) {
            int par_position = stmt.bind_parameter_index (par);
            stmt.bind_int (par_position, val);
        }

        private void set_parameter_int64 (Sqlite.Statement? stmt, string sql, string par, int64 val) {
            int par_position = stmt.bind_parameter_index (par);
            stmt.bind_int64 (par_position, val);
        }

        private void set_parameter_str (Sqlite.Statement? stmt, string sql, string par, string val) {
            int par_position = stmt.bind_parameter_index (par);
            stmt.bind_text (par_position, val);
        }
    }
}
