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
        PlayMyVideos.Settings settings;

        public signal void ended ();
        public signal void started (Objects.Video video);
        public signal void player_frame_resized (int width, int height);
        public signal void duration_changed (double duration);
        public signal void progress_changed (double progress);
        public signal void toggled (bool playing);

        public Objects.Video current_video { get; private set; }

        int last_width = 0;
        int last_height = 0;
        double last_dur = 0;

        uint progress_timer = 0;
        uint mouse_move_timer = 0;

        public ClutterGst.Playback playback { get; private set; }
        Clutter.Actor video_actor;
        GtkClutter.Embed clutter;
        VideoTimeLine timeline;
        Playlist playlist;

        construct {
            settings = PlayMyVideos.Settings.get_default ();

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
                    progress_changed (0);
                }
            });

            playback.eos.connect (() => {
                playback.playing = false;
                playback.uri = null;
                var vid = current_video;
                if (settings.repeat_mode == RepeatMode.ONE) {
                    current_video = null;
                    play (vid);
                    return;
                }

                if (next ()) {
                    return;
                }

                if (settings.repeat_mode == RepeatMode.ALL) {
                    play (vid.box.videos.first ().data);
                    return;
                }
                playlist.unselect_all ();
                ended ();
            });

            playback.notify["playing"].connect (() => {
                if (playback.playing) {
                    started (current_video);
                    progress_timer = GLib.Timeout.add (250, () => {
                        progress_changed (playback.progress);
                        return true;
                    });
                    Interfaces.Inhibitor.instance.inhibit ();
                    hide_controls ();
                } else {
                    if (progress_timer != 0) {
                        Source.remove (progress_timer);
                        progress_timer = 0;
                    }
                    Interfaces.Inhibitor.instance.uninhibit ();
                }
                toggled (playback.playing);
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

            playlist = new Playlist (this);
            var right_actor = new GtkClutter.Actor.with_contents (playlist);
            right_actor.add_constraint (new Clutter.AlignConstraint (stage, Clutter.AlignAxis.X_AXIS, 1));
            right_actor.add_constraint (new Clutter.AlignConstraint (stage, Clutter.AlignAxis.Y_AXIS, 0));
            right_actor.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.HEIGHT, 0));
            stage.add_child (right_actor);

            timeline = new VideoTimeLine (this);
            var bottom_actor = new GtkClutter.Actor.with_contents (timeline);
            bottom_actor.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 0));
            bottom_actor.add_constraint (new Clutter.AlignConstraint (stage, Clutter.AlignAxis.Y_AXIS, 1));
            stage.add_child (bottom_actor);
        }

        public PlayerView () {
            build_ui ();
        }

        private void build_ui () {
            this.events |= Gdk.EventMask.POINTER_MOTION_MASK;

            this.button_press_event.connect ((event) => {
                if (event.button == 1) {
                    toogle_playing ();
                }
                return false;
            });

            this.motion_notify_event.connect ((event) => {
                return hide_controls ();
            });
            this.add (clutter);
        }

        public void play (Objects.Video video) {
            if (current_video == video) {
                if (!playback.playing) {
                    playback.playing = true;
                }
                return;
            }
            current_video = video;
            if (current_video.box != null) {
                playlist.show_box (current_video.box);
            }
            playback.uri = video.uri;
            playback.playing = true;
        }

        public void pause () {
            playback.playing = false;
        }

        public bool next () {
            if (current_video == null || current_video.box == null) {
                return false;
            }
            var next = current_video.box.get_next_video (current_video);
            if (next != null) {
                play (next);
                return true;
            }
            return false;
        }

        public void toogle_playing () {
            playback.playing = !playback.playing;
        }

        public void seek_seconds (int seconds) {
            var duration = playback.duration;
            var progress = playback.progress;
            var new_progress = ((duration * progress) + (double)seconds) / duration;
            playback.progress = new_progress.clamp (0.0, 1.0);
        }

        private bool hide_controls () {
            if (mouse_move_timer != 0) {
                Source.remove (mouse_move_timer);
                mouse_move_timer = 0;
            }

            if (playback.playing) {
                mouse_move_timer = GLib.Timeout.add (2000, () => {
                    timeline.set_reveal_child (false);
                    playlist.set_reveal_child (false);
                    PlayMyVideosApp.instance.mainwindow.hide_mouse_cursor ();
                    mouse_move_timer = 0;
                    return false;
                });
            }

            timeline.set_reveal_child (true);
            if (playlist.has_episodes) {
                playlist.set_reveal_child (true);
            }
            return false;
        }

        public void reset () {
            if (playback.playing) {
                playback.playing = false;
            }
            playback.uri = null;
        }
    }
}
