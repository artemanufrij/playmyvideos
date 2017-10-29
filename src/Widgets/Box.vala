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
    public class Box : Gtk.FlowBoxChild {
        public Objects.Box box { get; private set; }

        Gtk.Image cover;

        public Box (Objects.Box box) {
            this.box = box;
            build_ui ();

            this.box.cover_changed.connect (() => {
                cover.pixbuf = this.box.cover.scale_simple (128, 181, Gdk.InterpType.BILINEAR);
            });
        }

        private void build_ui () {
            this.tooltip_text = box.title;

            var content = new Gtk.Grid ();
            content.margin = 12;
            content.halign = Gtk.Align.CENTER;
            content.row_spacing = 6;

            cover = new Gtk.Image ();
            cover.get_style_context ().add_class ("card");
            cover.halign = Gtk.Align.CENTER;
            if (box.cover == null) {
                cover.set_from_icon_name ("video-x-generic-symbolic", Gtk.IconSize.DIALOG);
                cover.height_request = 181;
                cover.width_request = 128;
            } else {
                cover.pixbuf = box.cover.scale_simple (128, 181, Gdk.InterpType.BILINEAR);
            }

            var title = new Gtk.Label (box.title);
            title.max_width_chars = 0;
            title.justify = Gtk.Justification.CENTER;
            title.set_line_wrap (true);

            content.attach (cover, 0, 0);
            content.attach (title, 0, 1);

            this.add (content);
            this.valign = Gtk.Align.START;

            this.show_all ();
        }
    }
}
