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

namespace PlayMyVideos.Widgets {
    public class SubTitleRow : Gtk.ListBoxRow {
        public string subtitle { get; private set; }
        string _path = "";
        public new string path {
            get {
                return _path;
            } set {
                _path = value;
                subtitle = Path.get_basename (_path);
                uri = File.new_for_path (path).get_uri ();
            }
        }

        string _uri = "";
        public string uri {
            get {
                return _uri;
            } private set {
                _uri = value;
            }
        }

        public SubTitleRow (Objects.Video video, string path) {
            this.path = path;
            var lab = new Gtk.Label (subtitle);
            lab.margin = 4;
            lab.halign = Gtk.Align.START;
            this.add (lab);
        }
    }
}
