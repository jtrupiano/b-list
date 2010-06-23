require 'twitter_oauth'
require 'ruby-debug'

module B
  class List
    def initialize(app, options={})
      @app = app
      @list_owner       = options[:list_owner]
      @list_name        = options[:list_name]
      @consumer_key     = options[:consumer_key]
      @consumer_secret  = options[:consumer_secret]
    end
    
    def call(env)
      @env = env

      # if I'm already authenticated, then don't bother
      return @app.call(env) if authenticated_with_b_list?
      
      if returning_from_twitter?
        debugger
        twitter_client.authorize(
          session[:request_token],
          session[:request_token_secret],
          :oauth_verifier => params["oauth_verifier"]
        )
        session.delete(:request_token)
        session.delete(:request_token_secret)

        if authenticated_with_twitter_list?
          session["b_list_authenticated_user"] = twitter_client.info
          [302, {'Location' => session[:requested_path], 'Content-Type' => 'text/html'}, ["Successfully authenticated, redirecting back"]]
        else
          [200, {'Content-Type' => 'text/html'}, ["You are not on the twitter list"]]
        end
      else
        request_token = twitter_client.request_token(:oauth_callback => oauth_callback_url)
        session[:request_token]         = request_token.token
        session[:request_token_secret]  = request_token.secret
        session[:requested_path]          = @env["PATH_INFO"]
        [302, {'Location' => request_token.authorize_url, 'Content-Type' => 'text/html'}, ["Redirecting to Twitter for authentication"]]
      end
    end
    
    def twitter_client
      @twitter_client ||= TwitterOAuth::Client.new(:consumer_key => @consumer_key, :consumer_secret => @consumer_secret)
    end
    
    def authenticated_with_b_list?
      !session["b_list_authenticated_user"].nil?
    end
    
    # we've already authenticated as an admin
    def authenticated_with_twitter_list?
      twitter_client.authorized? && list_members(twitter_client).include?(twitter_client.info['screen_name'])
    end
    
    def list_members(twitter_client)
      # I think this only returns 10 or 20.  we may want to look at #get_member_of_list
      twitter_client.list_members(@list_owner, @list_name)['users'].map{|info| info['screen_name']}
    end
    
    def returning_from_twitter?
      @env["PATH_INFO"] == oauth_callback_path
    end
    
    def oauth_callback_path
      "/b-list/oauth_callback"
    end
    
    def oauth_callback_url
      protocol = @env['SERVER_PORT'] == 443 ? "https" : "http"
      "#{protocol}://#{@env['SERVER_NAME']}:#{@env['SERVER_PORT']}#{oauth_callback_path}"
    end
    
    def session
      @session ||= @env["rack.session"] || {}
    end
    
    def params
      @env["QUERY_STRING"].split("&").inject({}) {|hsh, key_value|
        key, value = key_value.split("=")
        hsh[key] = value
        hsh
      }
    end
  end
end