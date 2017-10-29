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
    public static Gdk.Pixbuf? align_pixbuf_for_thumbnail_normal (Gdk.Pixbuf p) {
        Gdk.Pixbuf? pixbuf = p;
        int dif = (pixbuf.height - 50) / 2;
        pixbuf = new Gdk.Pixbuf.subpixbuf (pixbuf, 8, dif, pixbuf.width - 16, 50);
        return pixbuf;
    }

    public static Gdk.Pixbuf? align_and_scale_pixbuf_for_cover (Gdk.Pixbuf p) {
        Gdk.Pixbuf? pixbuf = p;

        int dest_height = 362;
        int dest_width = 256;

        int height = pixbuf.height;
        int width = pixbuf.width;

        if (width < height / 1.41) {
            int dif = (int)((pixbuf.height - width * 1.41) / 2);
            pixbuf = new Gdk.Pixbuf.subpixbuf (pixbuf, 0, dif, width, (int)(width * 1.41));
        } else {
            int dif = (int)((pixbuf.width - height / 1.41) / 2);
            pixbuf = new Gdk.Pixbuf.subpixbuf (pixbuf, dif, 0, (int)(height / 1.41), height);
        }

        pixbuf = pixbuf.scale_simple (dest_width, dest_height, Gdk.InterpType.BILINEAR);
        return pixbuf;
    }
}
