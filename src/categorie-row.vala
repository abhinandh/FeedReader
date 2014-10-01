/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * categorie-row.vala
 * Copyright (C) 2014 JeanLuc <jeanluc@jeanluc-desktop>
 *
 * tt-rss is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * tt-rss is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class categorieRow : baseRow {

	private string m_name;
	private Gtk.EventBox m_eventbox;
	private Gdk.Pixbuf m_state_collapsed;
	private Gdk.Pixbuf m_state_expanded;
	private int m_categorieID;
	private int m_parentID;
	private int m_level;
	private bool m_exists;
	private Gtk.Image m_icon_expanded;
	private Gtk.Image m_icon_collapsed;
	private bool m_collapsed;
	public signal void collapse(bool collapse, int catID);

	public categorieRow (string name, int categorieID, int orderID, string unread_count, int parentID, int level, int expanded) {
	
		this.get_style_context().add_class("feed-list-row");
		m_level = level;
		m_parentID = parentID;
		if(expanded == 0)
			m_collapsed = true;
		else
			m_collapsed = false;
		m_name = name;
		m_exists = true;
		m_categorieID = categorieID;
		m_unread_count = unread_count;
		var rowhight = 30;
		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		m_eventbox = new Gtk.EventBox();
		m_eventbox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);

		string path = "/usr/share/RSSReader/categorie_expander.png";
		try{m_state_collapsed = new Gdk.Pixbuf.from_file(path);}catch(GLib.Error e){ warning(e.message);}
		m_state_expanded = m_state_collapsed.rotate_simple(Gdk.PixbufRotation.CLOCKWISE);
		m_icon_expanded = new Gtk.Image.from_pixbuf(m_state_expanded);
		m_icon_collapsed = new Gtk.Image.from_pixbuf(m_state_collapsed);

		m_label = new Gtk.Label(m_name);
		m_label.set_use_markup (true);
		m_label.set_size_request (0, rowhight);
		m_label.set_ellipsize (Pango.EllipsizeMode.END);
		m_label.set_alignment(0, 0.5f);

		m_eventbox.button_press_event.connect(() => {
			expand_collapse();
			return true;
		});

		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.set_transition_duration(500);

		m_spacer = new Gtk.Label("");
		m_spacer.set_size_request((level-1) * 24, rowhight);


		m_unread = new Gtk.Label("");
		m_unread.set_size_request (0, rowhight);
		m_unread.set_alignment(0.8f, 0.5f);
		set_unread_count(m_unread_count);

		if(m_collapsed)
			m_eventbox.add(m_icon_collapsed);
		else
			m_eventbox.add(m_icon_expanded);
		m_box.pack_start(m_spacer, false, false, 0);
		m_box.pack_start(m_eventbox, false, false, 8);
		m_box.pack_start(m_label, true, true, 0);
		m_box.pack_end(m_unread, false, false, 8);
		m_revealer.add(m_box);
		m_revealer.set_reveal_child(false);
		m_isRevealed = false;
		this.add(m_revealer);
		this.show_all();
	}

	public void expand_collapse()
	{
		if(m_collapsed)
		{
			m_collapsed = false;
			m_eventbox.remove(m_icon_collapsed);
			m_eventbox.add(m_icon_expanded);
			collapse(false, m_categorieID);
			dataBase.mark_categorie_expanded(m_categorieID, 1);
		}
		else
		{
			m_collapsed = true;
			m_eventbox.remove(m_icon_expanded);
			m_eventbox.add(m_icon_collapsed);
			collapse(true, m_categorieID);
			dataBase.mark_categorie_expanded(m_categorieID, 0);
		}
		
		this.show_all();
	}

	public int getID()
	{
		return m_categorieID;
	}

	public int getParent()
	{
		return m_parentID;
	}

	public int getLevel()
	{
		return m_level;
	}

	public void setExist(bool exists)
	{
		m_exists = exists;
	}

	public bool doesExist()
	{
		return m_exists;
	}

	public bool isExpanded()
	{
		return !m_collapsed;
	}

}
