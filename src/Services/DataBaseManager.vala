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
