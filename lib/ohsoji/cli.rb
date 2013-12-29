require "ohsoji"
require "thor"
require "twitter"
require "pit"
require "pry"
require "retry-handler"
require "im-kayac"

at_exit do
  pit = Pit.get('im.kayac.com')
  ImKayac.to(pit["username"]).password(pit["password"]).post('大掃除 done')
end


module Ohsoji
  class CLI < Thor

    desc "twitter", "ohsoji twitter"
    def twitter
      friends.each do |id|
        unless listed_users.include?(id)
          puts id
          Proc.new do
            begin
              tw.unfollow(id)
            rescue Twitter::Error::NotFound
              puts "NotFound id:#{id}"
            end
          end.retry(
            max: 3,
            wait: 3,
            accept_exception: Twitter::Error
          )
          sleep 10
        end
      end
    end

    desc "keep", "keep user"
    def keep
      listed_users.each do |id|
        unless friends.include?(id)
          puts id
          begin
            tw.follow(id)
          rescue Twitter::Error::Forbidden
            puts "Forbidden id:#{id}"
          end
          sleep 10
        end
      end
    end

    private
    def friends
      @friends ||= tw.friend_ids
    end

    def listed_users
      @listed_user ||= tw.lists.map{ |list|  tw.list_members(list.id).map(&:id) }.flatten.uniq
    end

    def tw
      @twitter ||= Twitter::REST::Client.new do |config|
        pit = Pit.get('twitter.com')
        config.consumer_key        = pit["consumer_key"]
        config.consumer_secret     = pit["consumer_secret"]
        config.access_token        = pit["oauth_token"]
        config.access_token_secret = pit["oauth_token_secret"]
      end
    end
  end
end
