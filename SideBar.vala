public class Test.SideBar : Gtk.Box {

    public Gtk.ListBox listbox { get; set; }
    public string? title { get; construct; }
    public bool has_title { get; set; }
    public SideBar (string? title) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 0,
            title: title
        );
    }

    construct {
        if (title != null) { // checks if title is null or specified
            var title_label = new Gtk.Label (title) {
                halign = Gtk.Align.START,
                margin_start = 10
            };
            title_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);
            has_title = true;
            // if title is specified and not null, has_title is set to true and it dictates
            // whether the listbox items will increase margin.
            append (title_label);
        }

        listbox = new Gtk.ListBox () { // the listbox is the primary widget where all items are added
            hexpand = true
        };
        append (listbox);
    }

    public void load_file_as_hierarchical (File file) { // this is the function that is ran only with a file
        if (file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS) == FileType.DIRECTORY) {
            listbox.prepend (new SideBarExpandableItem (file, 0, has_title, listbox));

            // expandable items for directories. It takes the file, hierarchy level
            // which is 0 if it is at the top of the hierarchy, has_title boolean
            // to dictate the start margin, and the listbox so we can add the contents of expandable items to it.

        } else if (file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS) == FileType.REGULAR) {
            listbox.prepend (new SideBarItem (file, 0, has_title));

            // same with the expandable with the only change being it does not need the listbox because this do not contain subitems.

        } else {
            print ("Unsupported file");
        }
    }

    public class SideBarItem : Gtk.Box { // The widget that holds the simple items or those items w/o subitems
        public string icon_name = "text-x-generic"; // the icon_name can be set in the future, now only for demo
        public int hierarchy_level { get; construct; } // more on this below
        public bool has_title { get; construct; } // the same has_title we set before.
        public File file { get; construct; } // the file itself

        public SideBarItem (File file, int hierarchy_level, bool has_title) {
            Object (
                orientation: Gtk.Orientation.HORIZONTAL,
                spacing: 0,
                file: file,
                hierarchy_level: hierarchy_level,
                has_title: has_title
            );
        }

        construct {
            // the icon can be set in the future but for now it is simple.
            if (icon_name != "") {
                append (new Gtk.Image.from_icon_name (icon_name) { 
                    pixel_size = 16,
                    margin_end = 5
                });
            }

            var filename_label = new Gtk.Label (file.get_basename ()) {
                // only the base name of the file is showed for now, so files with same filename may confuse.
                hexpand = true,
                xalign = -1
            };
            append (filename_label);

            halign = Gtk.Align.FILL; // this makes sure that the box takes all space in the listboxrow.
            margin_start = 10 + (hierarchy_level * 20) + ((int) has_title) * 10;

            // this is where it gets interesting. we have a basic margin of 10. 

            // For the hierarchy level,
            // it increases as you go lower to the hierarchy, which analogically means that if the 
            // grandparent is at hierarchy level 0, the child is at 1, and the grandchild at 2. We multiply
            // the hierarchy level with a ratio that dictates the starting margin based on your position in
            // the hierarchy. So to summarize, the higher hierarchy level, the bigger the starting margin.

            // For the has_title, since it is boolean, it can only be 1 or 0.
            // If has_title is 1, or there is a title, it will be multiplied to 10 or the additional margin
            // and result into 10, thus the additional margin. 
            // If has_title is 0, multiplied by 10 it will be 0, so there will not be additional starting margin.

            // so we add the base start margin, the margin depending on hierarchy level and the margin if there
            // is title to define the final starting margin of the item.

            height_request = 20; // this height can be changed.
            hexpand = true;
        }
    }

    public class SideBarExpandableItem : Gtk.Box {
        public int hierarchy_level { get; construct; }
        public bool has_title { get; construct; }
        public File file { get; construct; }
        public Gtk.ListBox? parent_box { get; construct; } // we have the listbox so we can add the subitems
        public List<SideBarExpandableItem> expandable_items_list = new List<SideBarExpandableItem> ();
        public List<SideBarItem> simple_items_list = new List<SideBarItem> ();
        // we create 2 items to house the simple and expandable items so that we know which to hide
        // and show when we expanded and compressed the expandable item.

        public SideBarExpandableItem (File file, int hierarchy_level, bool has_title, Gtk.ListBox? parent) {
            Object (
                orientation: Gtk.Orientation.HORIZONTAL,
                spacing: 0,
                file: file,
                hierarchy_level: hierarchy_level,
                has_title: has_title,
                parent_box: parent
            );
        }

        construct {
            var filename = "<b>%s</b>".printf (file.get_basename ()); 
            // since the expandable house children, they must be specified by bolding them
            var filename_label = new Gtk.Label (file.get_basename ()) {
                use_markup = true, // use markup to make use of above comment.
                hexpand = true,
                xalign = -1
            }; 
            append (filename_label);

            halign = Gtk.Align.FILL;
            margin_start = 10 + (hierarchy_level * 20) + ((int) has_title) * 10; // same situation as SideBarItem
            height_request = 20;
            hexpand = true;
            can_focus = false; // expandables can't receive focus because they only expand or compress.

            var loop = new MainLoop (); // the loop which will gather the contents of directory into items.

	        file.enumerate_children_async.begin ("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, Priority.DEFAULT, null, (obj, res) => {
		        try {
			        FileEnumerator enumerator = file.enumerate_children_async.end (res);
			        FileInfo info;
			        while ((info = enumerator.next_file (null)) != null) {
				        append_to_hierarchy (enumerator.get_child (info)); // append the children to hierarchy
			        }
		        } catch (Error e) {
			        print ("Error: %s\n", e.message);
		        }

		        loop.quit ();
	        });

	        loop.run (); // this loop only runs in the expandables because expandables hold directory

	        if (hierarchy_level > 0) {
	            var hierarchy_directory_indicator = new Gtk.Image.from_icon_name ("go-next-symbolic") {
	                margin_end = 5
	            };
	            hierarchy_directory_indicator.insert_before (this, filename_label);
	            margin_start = 7 + (hierarchy_level * 10) + ((int) has_title) * 5;

	            // this ensures that the subitems that are folders are marked as expandable.
	            // we only do this in the subitems of the toplevel so we set hierarchy_level > 0
	        }

            var expander_button = new Gtk.Button.from_icon_name ("go-next-symbolic") {
                halign = Gtk.Align.END, // it goes to the end of the item
                valign = Gtk.Align.CENTER,
                margin_end = 10,
                can_focus = false // it also can't focus
            }; // this is the button that expands (shows) and compresses (hides) to show the subitems.
            expander_button.add_css_class (Granite.STYLE_CLASS_FLAT);

            var expand_bool = false; // this is only a variable to store expansion state to.
            expander_button.clicked.connect (() => {
                if (!expand_bool) {
                    expander_button.icon_name = "go-down-symbolic"; // changes the image to indicate expanded
                    expandable_items_list.foreach ((item) => { // shows the expandable items
                        item.show ();
                    });
                    simple_items_list.foreach ((item) => { // shows the simple items
                        item.show ();
                    });
                    expand_bool = !expand_bool; // set the expansion with the state of the expander button
                } else {
                    expander_button.icon_name = "go-next-symbolic"; // indicate that is is compressed
                    expandable_items_list.foreach ((item) => {
                        item.hide (); // hide the subitems
                    });
                    simple_items_list.foreach ((item) => {
                        item.hide ();
                    });
                    expand_bool = !expand_bool;
                }
            });

            append (expander_button);

            unmap.connect (() => {
                if (expand_bool = true) {
                    expand_bool = false;
                    expander_button.icon_name = "go-next-symbolic";
                }

                expandable_items_list.foreach ((item) => {
                    item.hide ();
                });
                simple_items_list.foreach ((item) => {
                    item.hide ();
                });
            });
            // this ^^^ ensures that even if some items in the subitems are open when a higher level expandable
            // is closed,the subitems will be closed.
        }

        public void append_to_hierarchy (File file) {
            if (file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS) == FileType.DIRECTORY) {
                var expandable = new SideBarExpandableItem (file, hierarchy_level + 1, has_title, parent_box);
                expandable.hide (); // subitems are hidden by default.
                parent_box.listbox.prepend (expandable); // add the expandable subitem to the main listbox.
                expandable_items_list.append (expandable); // add the item to the list.
            } else if (file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS) == FileType.REGULAR) {
                var simple_item = new SideBarItem (file, hierarchy_level + 1, has_title);
                simple_item.hide ();
                parent_box.listbox.prepend (simple_item);
                simple_items_list.append (simple_item);
            } else {
                print ("Unsupported file");
            }
        }
    }
}
