/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * article-list.vala
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

public class articleList : Gtk.Stack {

	private Gtk.ScrolledWindow m_currentScroll;
	private Gtk.ScrolledWindow m_scroll1;
	private Gtk.ScrolledWindow m_scroll2;
	private Gtk.ListBox m_currentList;
	private Gtk.ListBox m_List1;
	private Gtk.ListBox m_List2;
	private Gtk.Adjustment m_currentScroll_adjustment;
	private double m_lmit;
	private int m_displayed_articles;
	private int m_current_feed_selected;
	private bool m_only_unread;
	private bool m_only_marked;
	private string m_searchTerm;
	private int m_limit;
	public bool id_is_feedID;
	public signal void row_activated(articleRow? row);
	public signal void load_more();
	public signal void updateFeedList();
	

	public articleList () {
		m_lmit = 0.8;
		m_displayed_articles = 0;
		m_current_feed_selected = 0;
		id_is_feedID = true;
		m_searchTerm = "";
		m_limit = 15;
		
		
		m_List1 = new Gtk.ListBox();
		m_List1.set_selection_mode(Gtk.SelectionMode.SINGLE);
		m_List1.get_style_context().add_class("article-list");
		m_List2 = new Gtk.ListBox();
		m_List2.set_selection_mode(Gtk.SelectionMode.SINGLE);
		m_List2.get_style_context().add_class("article-list");
		
		
		m_scroll1 = new Gtk.ScrolledWindow(null, null);
		m_scroll1.set_size_request(400, 500);
		m_scroll1.add(m_List1);
		m_scroll2 = new Gtk.ScrolledWindow(null, null);
		m_scroll2.set_size_request(400, 500);
		m_scroll2.add(m_List2);

		m_currentList = m_List1;
		m_currentScroll = m_scroll1;

		m_currentScroll_adjustment = m_currentScroll.get_vadjustment();
		m_currentScroll_adjustment.value_changed.connect(() => {
			var current = m_currentScroll_adjustment.get_value();
			var page = m_currentScroll_adjustment.get_page_size();
			var max = m_currentScroll_adjustment.get_upper();
			if((current + page)/max > m_lmit)
			{
				load_more();
			}
		});

		m_List1.row_activated.connect((row) => {
			row_activated((articleRow)row);
		});
		m_List2.row_activated.connect((row) => {
			row_activated((articleRow)row);
		});

		m_currentList.key_press_event.connect((event) => {
			
			if(event.keyval == Gdk.Key.Down)
				move(true);
			else if(event.keyval == Gdk.Key.Up)
				move(false);
			
			return true;
		});

		this.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		this.set_transition_duration(100);
		this.add_named(m_scroll1, "list1");
		this.add_named(m_scroll2, "list2");
	}


	private void move(bool down)
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;
		

		var ArticleListChildren = m_currentList.get_children();

		if(!down){
			ArticleListChildren.reverse();
		}

		int current = ArticleListChildren.index(selected_row);

		current++;
		articleRow current_article = ArticleListChildren.nth_data(current) as articleRow;
		m_currentList.select_row(current_article);
		row_activated(current_article);
	}


	public void setOnlyUnread(bool only_unread)
	{
		m_only_unread = only_unread;
	}

	public void setOnlyMarked(bool only_marked)
	{
		m_only_marked = only_marked;
	}
	
	public void setSearchTerm(string searchTerm)
	{
		m_searchTerm = searchTerm;
	}

	public void setSelectedFeed(int feedID)
	{
		m_current_feed_selected = feedID;
	}


	public void createHeadlineList()
	{
		//FIXME: limit should depend on headline layout
		m_limit = 15;
		
		SQLHeavy.QueryResult headlines = dataBase.read_headlines(m_current_feed_selected, id_is_feedID, m_only_unread, m_only_marked, m_searchTerm, m_limit, m_displayed_articles);
		try{
			for (int row = 1 ; !headlines.finished ; row++, headlines.next () )
			{
				m_displayed_articles++;
				var unread = false;
				if(headlines.fetch_int(4) == 1)
					unread = true;

				var showIcon = false;
				if(m_current_feed_selected == 0)
					showIcon = true;
				else if(!id_is_feedID)
					showIcon = true;
			
				articleRow* tmpRow = new articleRow(
					                             headlines.fetch_string(1),
					                             unread,
					                             headlines.fetch_int(3).to_string(),
					                             headlines.fetch_string(2),
					                             headlines.fetch_int(3),
					                             headlines.fetch_int(0),
					                             headlines.fetch_int(5),
					                             showIcon
					                            );
				tmpRow->updateFeedList.connect(() => {updateFeedList();});
				m_currentList.add(tmpRow);
				tmpRow->reveal(true);
			}
		}catch(SQLHeavy.Error e){}
		m_currentList.show_all();
		if(m_currentList == m_List1)		 this.set_visible_child_name("list1");
		else if(m_currentList == m_List2)   this.set_visible_child_name("list2");
	}

	public void newHeadlineList()
	{
		if(m_currentList == m_List1)	m_currentList = m_List2;
		else							m_currentList = m_List1;
		
		m_displayed_articles = 0;
		var articleChildList = m_currentList.get_children();
		foreach(Gtk.Widget* row in articleChildList)
		{
			m_currentList.remove(row);
			row->destroy();
			delete row;
		}

		createHeadlineList();
	}


	public void updateHeadlineList()
	{
		var articleChildList = m_currentList.get_children();
		if(articleChildList != null)
		{
			var first_row = articleChildList.first().data as articleRow;
			int new_articles = dataBase.getRowNumberHeadline(first_row.m_articleID) -1;
			m_limit = m_displayed_articles + new_articles;
		}

		var headlines = dataBase.read_headlines(m_current_feed_selected, id_is_feedID, m_only_unread, m_only_marked, m_searchTerm, m_limit);
		
		bool found;

		try{
			for (int atRow = 1 ; !headlines.finished ; atRow++, headlines.next () )
			{
				found = false;
				var unread = false;
				if(headlines.fetch_int(4) == 1)
					unread = true;
			
				foreach(Gtk.Widget row in articleChildList)
				{
					var tmpRow = (articleRow)row;
					if(headlines.fetch_int(0) == tmpRow.m_articleID)
					{
						tmpRow.updateUnread(unread);
						found = true;
						break;
					}
				}

				if(!found)
				{
					var showIcon = false;
					if(m_current_feed_selected == 0)
						showIcon = true;
			
					articleRow* tmpRow = new articleRow(
							                         headlines.fetch_string(1),
							                         unread,
							                         headlines.fetch_int(3).to_string(),
							                         headlines.fetch_string(2),
							                         headlines.fetch_int(3),
							                         headlines.fetch_int(0),
						                             headlines.fetch_int(5),
							                         showIcon
							                        );
					tmpRow->updateFeedList.connect(() => {updateFeedList();});
					m_currentList.insert(tmpRow, 0);
					tmpRow->reveal(true);
				}
			}
		}catch(SQLHeavy.Error e){}
	}

	 
}