/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Services.Notifications : GLib.Object {
    private Notify.Notification notification;

    public signal void on_signal_weather_update ();
    public signal void on_signal_location_manual ();

    public signal void on_signal_highlight_task (Objects.Task task);
    public signal void send_local_notification (string title,
                                                string description,
                                                string icon_name,
                                                int    time,
                                                bool   remove_clipboard_task);

    public Notifications () {
        Notify.init ("Planner");
        start_notification ();
    }

    public void send_notification (string summary, string body, string icon) {
        var notification = new Notify.Notification (summary, body, icon);
        notification.set_urgency (Notify.Urgency.NORMAL);

        try {
            notification.show ();
        } catch (GLib.Error e) {
            warning ("Failed to show notification: %s", e.message);
        }
    }

    public void start_notification () {
        GLib.Timeout.add_seconds (15, () => {
            var all_tasks = new Gee.ArrayList<Objects.Task?> ();
            all_tasks = Application.database.get_all_reminder_tasks ();

            foreach (Objects.Task task in all_tasks) {
                var now_date = new GLib.DateTime.now_local ();
                var reminder_date = new GLib.DateTime.from_iso8601 (task.reminder_time, new GLib.TimeZone.local ());

                if (Application.utils.is_today (reminder_date)) {
                    if (now_date.get_hour () == reminder_date.get_hour ()) {
                        if (now_date.get_minute () == reminder_date.get_minute ()) {
                            var summary = "";
                            var body = task.content;

                            if (task.is_inbox == 1) {
                                summary = _("Inbox");
                            } else {
                                summary = Application.database.get_project (task.project_id).name;
                            }

                            notification = new Notify.Notification (summary, body, "com.github.alainm23.planner");
                            notification.set_urgency (Notify.Urgency.CRITICAL);

                            try {
                                notification.show ();
                                task.was_notified = 1;
                                Application.database.update_task (task);
                            } catch (GLib.Error e) {
                                warning ("Failed to show notification: %s", e.message);
                            }
                        }
                    }
                }
            }

            return true;
        });
    }
}
