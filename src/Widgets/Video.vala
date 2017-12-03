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
    public class Video : Gtk.ListBoxRow {
        public PlayMyVideos.Objects.Video video { get; private set; }
        public string title { get { return video.title; } }
        public int year { get { return video.year; } }

        Gtk.Image thumbnail;

        public Video (Objects.Video video) {

            this.video = video;
            this.video.thumbnail_normal_changed.connect (() => {
                thumbnail.pixbuf = video.thumbnail_normal;
            });
            this.video.removed.connect (() => {
                Idle.add (() => {
                    this.destroy ();
                    return false;
                });
            });
            build_ui ();
        }

        private void build_ui () {
            this.tooltip_text = video.title;

            var content = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            content.spacing = 6;
            content.margin = 6;

            thumbnail = new Gtk.Image ();
            thumbnail.pixbuf = video.thumbnail_normal;

            var icon_play = new Gtk.Image.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            icon_play.opacity = 0;
            var grid = new Gtk.Grid ();

            grid.attach (icon_play, 0, 0);
            grid.attach (thumbnail, 0, 0);

            var title = new Gtk.Label (video.title);
            title.xalign = 0;
            title.ellipsize = Pango.EllipsizeMode.END;
            content.pack_start (grid, false, false, 0);
            content.pack_start (title, true, true, 0);

            var event_box = new Gtk.EventBox ();
            event_box.events |= Gdk.EventMask.ENTER_NOTIFY_MASK;
            event_box.events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;
            event_box.add (content);

            this.add (event_box);

            event_box.enter_notify_event.connect (() => {
                icon_play.opacity = 1;
                return false;
            });
            event_box.leave_notify_event.connect (() => {
                icon_play.opacity = 0;
                return false;
            });
        }
    }
}
