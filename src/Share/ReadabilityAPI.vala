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

public class FeedReader.ReadabilityAPI : GLib.Object {

    private Rest.OAuthProxy m_oauth;
    private GLib.Settings m_settings;
    private string m_id;
    private string m_requestToken;
    private string m_accessToken;
    private string m_verifier;
    private string m_secret;
    private string m_username;
    private bool m_loggedIn;


    public ReadabilityAPI(string id)
    {
        m_id = id;
        m_settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/readability/%s/".printf(id));

        m_oauth = new Rest.OAuthProxy (
            ReadabilitySecrets.oauth_consumer_key,
            ReadabilitySecrets.oauth_consumer_secret,
            ReadabilitySecrets.base_uri,
            false);

        m_loggedIn = false;
    }

    public ReadabilityAPI.open(string id)
    {
        m_id = id;
        m_settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/readability/%s/".printf(id));
        m_username = m_settings.get_string("username");

        m_oauth = new Rest.OAuthProxy.with_token (
            ReadabilitySecrets.oauth_consumer_key,
            ReadabilitySecrets.oauth_consumer_secret,
            m_settings.get_string("oauth-access-token"),
            m_settings.get_string("oauth-access-token-secret"),
            ReadabilitySecrets.base_uri,
            false);

        m_loggedIn = true;
    }


    public bool getRequestToken()
    {
        try
        {
			m_oauth.request_token("oauth/request_token", ReadabilitySecrets.oauth_callback);
		}
        catch (Error e)
        {
			logger.print(LogMessage.ERROR, "ReadabilityAPI: cannot get request token: " + e.message);
            return false;
		}

		m_requestToken = m_oauth.get_token();
        return true;
    }

    public bool getAccessToken(string verifier)
    {
        if(verifier == "")
        {
            return false;
        }

        try {
			m_oauth.access_token("oauth/access_token", verifier);
		} catch (Error e) {
			logger.print(LogMessage.ERROR, "ReadabilityAPI: cannot get access token: " + e.message);
            return false;
		}

		m_accessToken = m_oauth.get_token();
		m_secret = m_oauth.get_token_secret();
        refreshUsername();
        writeData();

        return true;
    }

    public bool addBookmark(string url)
    {
        if(!isLoggedIn())
            return false;

        var call = m_oauth.new_call();
		m_oauth.url_format = "https://www.readability.com/api/rest/v1/";
		call.set_function ("bookmarks");
		call.set_method("POST");
		call.add_param("url", url);
		call.add_param("favorite", "1");

        call.run_async((call, error, obj) => {
        	logger.print(LogMessage.DEBUG, "ReadabilityAPI: status code " + call.get_status_code().to_string());
        	logger.print(LogMessage.DEBUG, "ReadabilityAPI: payload " + call.get_payload());
        }, null);
        return true;
    }

    public bool refreshUsername()
    {
        bool login = false;
        var call = m_oauth.new_call();
		m_oauth.url_format = "https://www.readability.com/api/rest/v1/";
		call.set_function ("users/_current");
		call.set_method("GET");

        try{
            call.run();
        }
        catch(Error e)
        {
            logger.print(LogMessage.ERROR, e.message);
        }

        if(call.get_status_code() == 403)
        {
            return login;
        }

        var parser = new Json.Parser();
        try{
            parser.load_from_data(call.get_payload());
        }
        catch (Error e) {
            logger.print(LogMessage.ERROR, "Could not load response to Message from readability");
            logger.print(LogMessage.ERROR, e.message);
        }

        var root_object = parser.get_root().get_object();
        if(root_object.has_member("username"))
        {
            m_username = root_object.get_string_member("username");
            login = true;

            if(m_settings != null)
            {
            	m_settings.set_string("username", m_username);
            	return login;
            }
        }

		m_loggedIn = login;
        return login;
    }

    public string getUsername()
    {
    	return m_username;
    }

    private bool isLoggedIn()
    {
        return m_loggedIn;
    }

    private void writeData()
    {

		m_settings.set_string("oauth-access-token", m_accessToken);
		m_settings.set_string("oauth-access-token-secret", m_secret);
		m_settings.set_string("username", m_username);
		setArray();
    }

    private void setArray()
    {
		var array = settings_share.get_strv("readability");

		foreach(string id in array)
		{
			if(id == m_id)
				return;
		}

		array += m_id;
		settings_share.set_strv("readability", array);
    }


    private void deleteArray()
    {
    	var array = settings_share.get_strv("readability");
    	string[] array2 = {};

    	foreach(string id in array)
		{
			if(id != m_id)
				array2 += id;
		}

		settings_share.set_strv("readability", array2);
    }


    public bool logout()
    {
    	var keys = m_settings.list_keys();
		foreach(string key in keys)
		{
			m_settings.reset(key);
		}

		deleteArray();
        return true;
    }

    public string getURL()
    {
		return	ReadabilitySecrets.base_uri + "oauth/authorize/" + "?oauth_token=" + m_requestToken;
    }

    public string getID()
    {
    	return m_id;
    }
}
