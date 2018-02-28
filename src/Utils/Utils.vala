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

namespace PlayMyVideos.Utils {
    public static string get_title_from_basename (string basename) {
        int index = basename.last_index_of_char ('.');
        if (index > -1) {
            return basename.substring (0, index);
        }
        return basename;
    }

    public static string get_box_title_from_path (string path) {
        string directory = Path.get_dirname (path);
        string return_value = Path.get_basename (directory);

        try {
            var regex = new GLib.Regex ("^season(\\s)?\\d*");
            MatchInfo match_info;
            if (regex.match (return_value.down (), 0, out match_info)) {
                return_value = Path.get_basename (Path.get_dirname(directory)) + " - " + return_value;
            }
        } catch(Error err) {
            warning (err.message);
        }

        return return_value;
    }

    public static int get_year_from_basename (string basename) {
        int return_value = 0;

        try {
            var regex = new GLib.Regex ("(?<=\\()[12]\\d\\d\\d(?=\\)\\.)");
            MatchInfo match_info;
            if (regex.match (basename, 0, out match_info)) {
                return_value = int.parse (match_info.fetch (0));
            }
        } catch (Error err) {
            warning (err.message);
        }

        return return_value;
    }

    public static string[] subtitle_extentions () {
        return {"sub", "srt", "smi", "ssa", "ass", "asc"};
    }

    public static void get_title_items (string box_title ,out string title, out int season, out int year) {
        season = 0;
        year = 0;
        GLib.Regex regex;
        // CHECK IF SEASON
        try {
            regex = new GLib.Regex ("(?<=\\- season )\\d*$");
            MatchInfo match_info;
            if (regex.match (box_title.down (), 0, out match_info)) {
                season = int.parse (match_info.fetch (0));
                title = box_title.substring (0, box_title.last_index_of ("-")).strip ();
                return;
            }
        } catch(Error err) {
            warning (err.message);
        }

        // CHECK IF TITLE HAS YAER ITEM
        try {
            regex = new GLib.Regex ("(?<=\\()[12]\\d\\d\\d(?=\\)$)");
            MatchInfo match_info;
            if (regex.match (box_title.down (), 0, out match_info)) {
                year = int.parse (match_info.fetch (0));
                title = box_title.substring (0, box_title.last_index_of ("(")).strip ();
                return;
            }
        } catch(Error err) {
            warning (err.message);
        }

        title = box_title;
    }

    public enum PlayFlags {
        VIDEO         = (1 << 0),
        AUDIO         = (1 << 1),
        TEXT          = (1 << 2),
        VIS           = (1 << 3),
        SOFT_VOLUME   = (1 << 4),
        NATIVE_AUDIO  = (1 << 5),
        NATIVE_VIDEO  = (1 << 6),
        DOWNLOAD      = (1 << 7),
        BUFFERING     = (1 << 8),
        DEINTERLACE   = (1 << 9),
        SOFT_COLORBALANCE = (1 << 10)
    }
}
