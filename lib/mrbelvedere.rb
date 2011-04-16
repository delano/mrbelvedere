# encoding: utf-8
unless defined?(BELVEDERE_HOME)
  BELVEDERE_LIB_HOME = File.expand_path(File.join(File.dirname(__FILE__), '..') )
end

require 'bundler/setup'

local_libs = %w{familia}
local_libs.each { |dir| 
  a = File.join(BELVEDERE_LIB_HOME, '..', 'opensource', dir, 'lib')
  $:.unshift a
}

require 'storable'
require 'familia'
require 'gibbler'
require 'useragent'
require 'addressable/uri'
require 'bluth'


class MrBelvedere < Storable
  module VERSION
    def self.to_s
      load_config
      [@version[:MAJOR], @version[:MINOR], @version[:PATCH]].join('.')
    end
    alias_method :inspect, :to_s
    def self.load_config
      require 'yaml'
      @version ||= YAML.load_file(File.join(BELVEDERE_LIB_HOME, 'VERSION.yml'))
    end
  end
end

class MrBelvedere < Storable
  BOT_REGEX = /(Google|Yahoo|Baidu|Bing|mlbot|Apple-PubSub|DoCoMo|Yandex|Sosospider|PostRank|Superfeedr|Stella)/
  module Fields
    HTTP_METHOD = :m
    REQUEST_URI = :u
    CURRENT_TIME = :t
    NETWORK_ID = :nid
    MESSAGE = :msg
  end
  module RequestsCollector
    def self.included klass
      klass.module_eval do
        list :requests, :class => Hash
      end
    end
    # event type
    # http method
    # URI path (without host or query params)
    # session id
    # props 
    # props[nid] network id (e.g. IP address)
    # props[cid] customer ID
    # props[ua]  User Agent
    # props[ref] HTTP referrer
    def add_request meth, uri
      props = {
        MrBelvedere::Fields::HTTP_METHOD => meth.to_s.downcase,
        MrBelvedere::Fields::REQUEST_URI => uri.to_s,
        MrBelvedere::Fields::CURRENT_TIME => Familia.now
      }.merge @props
      requests.unshift props # add to the end so we can read in reverse-chronological
    end
  end
  module ErrorsCollector
    def self.included klass
      klass.module_eval do
        list :errors, :class => Hash
      end
    end
    def add_error meth, uri, msg
      props = {
        MrBelvedere::Fields::HTTP_METHOD => meth.to_s.downcase,
        MrBelvedere::Fields::REQUEST_URI => uri.to_s,
        MrBelvedere::Fields::MESSAGE => msg,
        MrBelvedere::Fields::CURRENT_TIME => Familia.now
      }.merge @props
      errors.unshift props  # add to the end so we can read in reverse-chronological
    end
  end
  module ActiveStats
    module RedisObjectHelpers
      def recent duration=15.seconds
        now = Familia.now
        remrangebyscore 0, now-(1.hour)  # TMP: this should be done by a cron job
        revrangebyscore now, now-duration  # note the args are reversed
      end
    end
    module ClassMethods
      def active_stat name, common_opts={}
        opts = {
          :extend => RedisObjectHelpers
        }.merge common_opts
        zset [:active, name].join('_'), opts  # define the Redis sorted set
      end
    end
    def self.included obj
      super
      obj.extend ClassMethods
    end
    def active name, uniqueid
      self.send([:active, name].join('_')).add Familia.now.to_i, uniqueid
    end
  end
  module RecordStats
    BREAKDOWNS = {
      '30days'    => [60.days, 30.days],
      '7days'     => [14.days, 7.days],
      '24hours'   => [7.days, 24.hours],
      '1hour'     => [1.days, 1.hour]
    }
    module ClassMethods
      def record_stat prefix, common_opts={}
        BREAKDOWNS.each_pair do |suffix, args|
          opts = {
            :ttl => args.first,
            :quantize => args.last
          }.merge common_opts
          set [prefix, suffix].join('_'), opts  # define the Redis set
        end
      end
      def breakdowns prefix
        BREAKDOWNS.collect do |breakdown|
          [prefix, breakdown.first].join('_')
        end
      end
    end
    def self.included obj
      super
      obj.extend ClassMethods
    end
    def record prefix, uniqueid
      self.class.breakdowns(prefix).each do |breakdown|
        self.send(breakdown).add uniqueid
      end
    end
  end
  class Customer < Storable
    include Familia
    index [:src, :grp, :cid]
    field :cid
    field :src
    field :grp
    attr_accessor :blv, :props
    def init *args
      @props = args.pop if ::Hash === args.last
      if @props
        self.class.field_names.each { |k| 
          next unless @props.has_key?(k)
          v = @props.delete(k); self.send(:"#{k}=", v) 
        }
        @blv = @props.delete(:blv)
      end
      super unless args.empty?
      @t = Familia.now.to_i
    end
    def blv
      @blv || MrBelvedere.default
    end
    def src
      blv.src
    end
    def grp
      blv.grp
    end
  end
  class Session < Storable
    include Familia
    index [:src, :grp, :sid]
    field :sid
    field :nid
    field :cid
    field :ua
    field :ref
    field :src
    field :grp
    field :bot => Boolean
    field :t => Integer
    attr_accessor :blv, :props
    include MrBelvedere::RequestsCollector
    include MrBelvedere::ErrorsCollector
    def init *args
      @props = args.pop if ::Hash === args.last
      if @props
        self.class.field_names.each { |k| 
          next unless @props.has_key?(k)
          v = @props.delete(k); self.send(:"#{k}=", v) 
        }
        @blv = @props.delete(:blv)
      end
      super unless args.empty?
      @sid, @bot = $1, true if @ua && @ua.match(BOT_REGEX)
      @sid = MrBelvedere.normalize_sid(@sid)
      @t = Familia.now.to_i
    end
    def customer
      @customer ||= MrBelvedere::Customer.new @cid, :blv => blv
      @customer
    end
    def customer?
      !@cid.to_s.empty? && @cid.to_s != 'anon' && @cid.to_s != 'anonymous'
    end
    def bot?
      !@bot.to_s.empty?
    end
    def blv
      @blv || MrBelvedere.default
    end
    def src
      blv.src
    end
    def grp
      blv.grp
    end
  end
end

# MrBelvedere.add_request 'get', 'uri', 'sessid', :cid => 'delano', :nid => '1.2.3.4', :ua => 'Firefox', :ref => 'bs.com'
# MrBelvedere.redis.flushdb
# load 'lib/belvedere.rb'
# s=MrBelvedere::Session.new 'sessid'
class MrBelvedere < Storable
  include Familia
  include RecordStats
  include ActiveStats
  list :errors, :class => Hash
  hash :customers, :class => Hash
  index [:src, :grp]
  record_stat :visitors, :class => MrBelvedere::Session, :reference => true
  record_stat :customers, :class => MrBelvedere::Customer, :reference => true
  record_stat :bots, :class => MrBelvedere::Session, :reference => true
  active_stat :visitors, :class => MrBelvedere::Session, :reference => true
  active_stat :customers, :class => MrBelvedere::Customer, :reference => true
  active_stat :bots, :class => MrBelvedere::Session, :reference => true
  record_stat :referrers
  active_stat :referrers
  record_stat :pages
  active_stat :pages
  record_stat :views
  active_stat :views
  field :src
  field :grp
  field :uri_filters => Array
  field :nid_filters => Array
  field :props => Hash
  def init *args
    super
    @props ||= {}
    @nid_filters ||= []
    @uri_filters ||= []
  end
  def add_error meth, uri, sid, msg, props={}
    return if ignore? uri, props[MrBelvedere::Fields::NETWORK_ID]
    props[:blv] = self
    sess = MrBelvedere::Session.new sid, props
    MrBelvedere.redis.pipelined do
      sess.savenx   # don't overwrite an existing session
      sess.add_error meth, uri, msg
    end
  rescue => ex
    STDOUT.puts "MrBelvedere error: #{ex.message}"
    STDOUT.puts ex.backtrace
  end
  def add_request meth, uri, sid, props={}
    return if ignore? uri, props[MrBelvedere::Fields::NETWORK_ID]
    event_id = [meth, uri, sid, props, Familia.now].gibbler.base(36)
    props[:blv] = self
    sess = MrBelvedere::Session.new sid, props
    new_session = sess.savenx # don't overwrite an existing session
    MrBelvedere.redis.pipelined do
      sess.add_request meth, uri   # it was already given the props
      record :pages, uri
      active :pages, uri
      if new_session && sess.ref  
        record :referrers, sess.ref
        active :referrers, sess.ref
      end
      if sess.bot?
        record :bots, sess.index
        active :bots, sess.index
      else
        record :visitors, sess.index
        active :visitors, sess.index
        active :views, event_id
        record :views, event_id
        if sess.customer?
          sess.customer.savenx
          record :customers, sess.customer.index
          active :customers, sess.customer.index
        end
      end
    end
    self
  rescue => ex
    STDOUT.puts "MrBelvedere error: #{ex.message}"
    STDOUT.puts ex.backtrace
  end
  def ignore? uri, nid
    return true if nid_filters.member?(nid)
    return true if !uri_filters.select { |regex| uri.match(regex) }.empty?
    false
  end
  class << self
    def default
      @default ||= MrBelvedere.new :default, :web
      @default
    end
    def add_request *args
      default.add_request *args
    end
    def add_error *args
      default.add_error *args
    end
    def normalize_sid sid
      sid.to_s.slice 0, 63
    end
    def canonical_uri(uri)
      if uri.kind_of?(URI)
        uri = Addressable::URI.parse uri.to_s
      elsif uri.kind_of?(String)
        uri &&= uri.to_s
        uri.strip! unless uri.frozen?
        uri = "http://#{uri}" unless uri.match(/^https?:\/\//)
        uri = Addressable::URI.parse(uri)
      elsif uri.to_s.empty?
        uri = nil
      end
      if uri
        uri.scheme ||= 'http'
        uri.path = '/' if uri.path.to_s.empty?
      end
      uri
    end
    def time_at_the_next(quantum, now=Familia.now)
      Time.at(Familia.qnow(quantum, now)+quantum).utc
    end
  end
end
Mrbelvedere = MrBelvedere
MrB = MrBelvedere

require 'mrbelvedere/jobs'

# https://github.com/josh/useragent