public class Application : Gtk.Application {

    public Application () {
        Object (
            application_id: "com.owen.filetest",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var window = new Window (this);
        window.present ();
    }

    public static int main (string[] args) {
        var application = new Application ();

        return application.run (args);
    }
}

public class Window : Gtk.ApplicationWindow {

    public Window (Gtk.Application app) {
        Object (application: app);
    }

    construct {
        var sidebar = new Test.SideBar (null); // if title is null, the hierarchy adjusts their start margin

        var welcome = new Granite.Placeholder ("SideBar Test") {
            description = "Pick a file or folder to display on the sidebar.",
            icon = new ThemedIcon ("dialog-warning"),
            hexpand = true
        };

        var open_folder = welcome.append_button (
            new ThemedIcon ("folder-open"),
            "Pick File",
            "You just have to pick a file :)."
        );

        var separating_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        separating_box.append (sidebar);
        separating_box.append (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        separating_box.append (welcome);

        // For dialog below, I don't know how to select both folder and file
        var dialog = new Gtk.FileChooserDialog ("Pick file", this, Gtk.FileChooserAction.SELECT_FOLDER);
        dialog.add_button ("Cancel", Gtk.ResponseType.CANCEL);
        dialog.add_button ("Open", Gtk.ResponseType.ACCEPT);

        open_folder.clicked.connect (() => {
            dialog.present ();
        });

        dialog.response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.CANCEL) {
                dialog.destroy ();
            } else if (response_id == Gtk.ResponseType.ACCEPT) {
                sidebar.load_file_as_hierarchical (dialog.get_file ()); // this loads the file from dialog and creates the hierarchy
                dialog.destroy ();
            }
        });

        child = separating_box;
        title = "File Test";
        default_width = 960;
        default_height = 640;

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = (
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
        );

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = (
                granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
            );
        });
    }
}
