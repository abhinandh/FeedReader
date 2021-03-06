//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public class FeedReader.TagRow : Gtk.ListBoxRow {

	private Gtk.Box m_box;
	private Gtk.Label m_label;
	private bool m_exits;
	private string m_catID;
	private int m_color;
	private ColorCircle m_circle;
	private ColorPopover m_pop;
	private Gtk.Revealer m_revealer;
	private Gtk.Label m_unread;
	private uint m_unread_count;
	public string m_name { get; private set; }
	public string m_tagID { get; private set; }


	public TagRow (string name, string tagID, int color)
	{
		this.get_style_context().add_class("feed-list-row");
		m_exits = true;
		m_color = color;
		m_name = name.replace("&","&amp;");
		m_tagID = tagID;
		m_catID = CategoryID.TAGS;

		var rowhight = 30;
		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

		m_circle = new ColorCircle(m_color);
		m_circle.margin_start = 24;
		m_pop = new ColorPopover(m_circle);

		m_circle.clicked.connect((color) => {
			m_pop.show_all();
		});

		m_pop.newColorSelected.connect((color) => {
			m_circle.newColor(color);
			feedDaemon_interface.updateTagColor(m_tagID, color);
		});

		m_label = new Gtk.Label(m_name);
		m_label.set_use_markup (true);
		m_label.set_size_request (0, rowhight);
		m_label.set_ellipsize (Pango.EllipsizeMode.END);
		m_label.set_alignment(0, 0.5f);

		m_box.pack_start(m_circle, false, false, 8);
		m_box.pack_start(m_label, true, true, 0);

		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.add(m_box);
		m_revealer.set_reveal_child(false);
		this.add(m_revealer);
		this.show_all();
	}

	public void update(string name)
	{
		m_label.set_text(name.replace("&","&amp;"));
		m_label.set_use_markup (true);
	}

	public string getID()
	{
		return m_tagID;
	}

	public void setExits(bool subscribed)
	{
		m_exits = subscribed;
	}

	public bool stillExits()
	{
		return m_exits;
	}

	public bool isRevealed()
	{
		return m_revealer.get_reveal_child();
	}

	public void reveal(bool reveal, uint duration = 500)
	{
		if(settings_state.get_boolean("no-animations"))
		{
			m_revealer.set_transition_type(Gtk.RevealerTransitionType.NONE);
			m_revealer.set_transition_duration(0);
			m_revealer.set_reveal_child(reveal);
			m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
			m_revealer.set_transition_duration(500);
		}
		else
		{
			m_revealer.set_transition_duration(duration);
			m_revealer.set_reveal_child(reveal);
		}
	}

}
