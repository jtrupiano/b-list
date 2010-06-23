require 'rubygems'
require 'rack'
require 'lib/b-list'

require 'sinatra'

use B::List, {
  :list_owner => 'blah',
  :list_name => 'blah',
  :consumer_key => 'blah', 
  :consumer_secret => 'blah'
}

get "/" do
  "We hit the root which is public"
end

get "/public" do
  "We hit a public page"
end

get "/protected" do
  "We hit the protected page with user #{session['b_list_authenticated_user']}"
end
