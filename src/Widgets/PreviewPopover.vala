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
    public class PreviewPopover : Gtk.Popover {

        ClutterGst.Playback playback;
        GtkClutter.Embed clutter;

        uint looping_timer_id = 0;

        Objects.Video _current_video = null;
        public Objects.Video current_video {
            get {
                return _current_video;
            } set {
                _current_video = value;
                new Thread<void*> (null, () => {
                    playback.uri = current_video.uri;
                    int flags;
                    playback.get_pipeline ().get ("flags", out flags);
                    flags &= ~Utils.PlayFlags.TEXT;
                    flags &= ~Utils.PlayFlags.AUDIO;
                    playback.get_pipeline ().set ("flags", flags);
                    return null;
                });
            }
        }

        public PreviewPopover () {
            clutter = new GtkClutter.Embed ();
            clutter.margin = 2;
            var stage = clutter.get_stage ();
            stage.background_color = {0, 0, 0, 0};

            playback = new ClutterGst.Playback ();

            var aspect_ratio = new ClutterGst.Aspectratio ();
            aspect_ratio.paint_borders = false;
            aspect_ratio.player = playback;
            aspect_ratio.size_change.connect ((width, height) => {
                clutter.set_size_request (200, (int)(((double) (height * 200)) / ((double) width)));
            });

            var video_actor = new Clutter.Actor ();
            video_actor.content = aspect_ratio;
            video_actor.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 0));
            video_actor.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.HEIGHT, 0));

            stage.add_child (video_actor);

            build_ui ();

            this.hide.connect (() => {
                playback.playing = false;
                if (looping_timer_id > 0) {
                    Source.remove (looping_timer_id);
                    looping_timer_id = 0;
                }
            });
        }

        private void build_ui () {
            this.modal = false;
            this.can_focus = false;

            this.add (clutter);

            this.show_all ();
            this.hide ();
        }

        public void update_position (int x) {
            var pointing = this.pointing_to;
            pointing.x = x;

            if (pointing.width == 0) {
                pointing.width = 2;
                pointing.x -= 1;
            } else {
                pointing.width = 0;
            }

            this.set_pointing_to (pointing);
        }

        public void preview_progress (double progress) {
            if (looping_timer_id > 0) {
                Source.remove (looping_timer_id);
                looping_timer_id = 0;
            }
            if (progress > 1 || progress < 0) {
                return;
            }
            playback.progress = progress;
            playback.playing = true;

            this.show ();

            looping_timer_id = Timeout.add (5000, () => {
                playback.playing = false;
                preview_progress (progress);
                return false;
            });
        }
    }
}
