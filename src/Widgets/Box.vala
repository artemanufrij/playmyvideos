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
        PlayMyVideos.Services.LibraryManager library_manager;
        public Objects.Box box { get; private set; }
        public string title { get { return box.title; } }

        Gtk.Image cover;
        Gtk.Menu menu;

        string video_symbolic = "video-x-generic-symbolic";

        construct {
            library_manager = PlayMyVideos.Services.LibraryManager.instance;
        }

        public Box (Objects.Box box) {
            this.box = box;
            build_ui ();
            this.box.cover_changed.connect (() => {
                Idle.add (() => {
                    cover.pixbuf = this.box.cover.scale_simple (128, 181, Gdk.InterpType.BILINEAR);
                    return false;
                });
            });
        }

        private void build_ui () {
            this.tooltip_text = box.title;

            var content = new Gtk.Grid ();
            content.margin = 12;
            content.halign = Gtk.Align.CENTER;
            content.row_spacing = 6;

            var event_box = new Gtk.EventBox ();
            event_box.button_press_event.connect (show_context_menu);

            menu = new Gtk.Menu ();
            var menu_new_cover = new Gtk.MenuItem.with_label (_("Set new Cover…"));
            menu_new_cover.activate.connect (() => {
                var new_cover = library_manager.choose_new_cover ();
                if (new_cover != null) {
                    try {
                        var pixbuf = new Gdk.Pixbuf.from_file (new_cover);
                        box.set_new_cover (pixbuf);
                    } catch (Error err) {
                        warning (err.message);
                    }
                }
            });
            menu.append (menu_new_cover);
            menu.show_all ();

            cover = new Gtk.Image ();
            cover.get_style_context ().add_class ("card");
            cover.halign = Gtk.Align.CENTER;

            var title = new Gtk.Label (box.title);
            title.max_width_chars = 0;
            title.justify = Gtk.Justification.CENTER;
            title.set_line_wrap (true);

            content.attach (cover, 0, 0);
            content.attach (title, 0, 1);

            event_box.add (content);

            this.add (event_box);
            this.valign = Gtk.Align.START;

            this.show_all ();

            if (box.cover == null) {
                cover.set_from_icon_name (video_symbolic, Gtk.IconSize.DIALOG);
                cover.height_request = 181;
                cover.width_request = 128;

                if (box.videos.length () > 0) {
                    var first = box.videos.first ().data;
                    load_cover_from_video (first);
                } else {
                    box.video_added.connect (load_cover_from_video);
                }

            } else {
                cover.pixbuf = box.cover.scale_simple (128, 181, Gdk.InterpType.BILINEAR);
            }
        }

        private bool show_context_menu (Gtk.Widget sender, Gdk.EventButton evt) {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                menu.popup (null, null, null, evt.button, evt.time);
                return true;
            }
            return false;
        }

        private void load_cover_from_video (Objects.Video video) {
            box.video_added.disconnect (load_cover_from_video);

            video.thumbnail_large_changed.connect (() => {
                if (cover.icon_name == video_symbolic) {
                    Idle.add (() => {
                        cover.pixbuf = PlayMyVideos.Utils.align_and_scale_pixbuf_for_cover (video.thumbnail_large).scale_simple (128, 181, Gdk.InterpType.BILINEAR);
                        return false;
                    });
                }
            });
            if (video.thumbnail_large != null && cover.icon_name == video_symbolic) {
                cover.pixbuf = PlayMyVideos.Utils.align_and_scale_pixbuf_for_cover (video.thumbnail_large).scale_simple (128, 181, Gdk.InterpType.BILINEAR);
            }
        }
    }
}
