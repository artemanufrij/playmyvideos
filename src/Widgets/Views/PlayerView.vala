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

namespace PlayMyVideos.Widgets.Views {
    public class PlayerView : Gtk.Grid {

        public signal void player_frame_resized (int width, int height);
        public signal void duration_changed (double duration);

        int last_width = 0;
        int last_height = 0;
        double last_dur = 0;

        ClutterGst.Playback playback;
        Clutter.Actor video_actor;
        GtkClutter.Embed clutter;
        VideoTimeLine timeline;

        construct {
            clutter = new GtkClutter.Embed ();
            playback = new ClutterGst.Playback ();
            playback.new_frame.connect ((frame) => {
                var current_width = frame.resolution.width;
                var current_height = frame.resolution.height;
                var current_dur = playback.duration;
                if (last_width != current_width || last_height != current_height) {
                    last_width = current_width;
                    last_height = current_height;
                    player_frame_resized (last_width, last_height);
                }
                if (last_dur != current_dur) {
                    last_dur = current_dur;
                    duration_changed (current_dur);
                }
            });

            video_actor = new Clutter.Actor ();

            var stage = (Clutter.Stage)clutter.get_stage ();
            stage.background_color = {0, 0, 0, 0};

            var aspect_ratio = new ClutterGst.Aspectratio ();
            aspect_ratio.paint_borders = false;
            aspect_ratio.player = playback;

            video_actor.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 0));
            video_actor.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.HEIGHT, 0));
            video_actor.content = aspect_ratio;
            stage.add_child (video_actor);

            timeline = new VideoTimeLine (this);
            var bottom_actor = new GtkClutter.Actor.with_contents (timeline);
            bottom_actor.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 0));
            bottom_actor.add_constraint (new Clutter.AlignConstraint (stage, Clutter.AlignAxis.Y_AXIS, 1));
            stage.add_child (bottom_actor);

            timeline.show_all ();
        }

        public PlayerView () {
            build_ui ();
        }

        private void build_ui () {
            this.add (clutter);
        }

        public void play (Objects.Video video) {
            if (playback.uri != video.uri) {
                playback.uri = video.uri;
            }
            playback.playing = true;
        }

        public void pause () {
            playback.playing = false;
        }
    }
}
