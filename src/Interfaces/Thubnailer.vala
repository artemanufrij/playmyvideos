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

namespace PlayMyVideos.Interfaces {
    [DBus (name = "org.freedesktop.thumbnails.Thumbnailer1")]
    private interface Tumbler : GLib.Object {
        public abstract async uint Queue (string[] uris, string[] mime_types, string flavor, string sheduler, uint handle_to_dequeue) throws GLib.IOError, GLib.DBusError;
        public signal void Finished (uint handle);
    }

    public class DbusThumbnailer : GLib.Object {
        static DbusThumbnailer _instance = null;
        public static DbusThumbnailer instance {
            get {
                if (_instance == null) {
                    _instance = new DbusThumbnailer ();
                }
                return _instance;
            }
        }

        private Tumbler tumbler;
        private const string THUMBNAILER_IFACE = "org.freedesktop.thumbnails.Thumbnailer1";
        private const string THUMBNAILER_SERVICE = "/org/freedesktop/thumbnails/Thumbnailer1";

        public signal void finished (uint handle);

        private DbusThumbnailer () {}

        construct {
            try {
                tumbler = Bus.get_proxy_sync (BusType.SESSION, THUMBNAILER_IFACE, THUMBNAILER_SERVICE);
                tumbler.Finished.connect ((handle) => { finished (handle); });
            } catch (Error e) {
                warning (e.message);
            }
        }

        public void create_thumbnails (Gee.ArrayList<string> uris, Gee.ArrayList<string> mimes, string size){
            tumbler.Queue.begin (uris.to_array (), mimes.to_array (), size, "default", 0);
        }
    }
}
