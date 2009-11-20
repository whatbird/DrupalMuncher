require 'rubygems'
require 'activerecord'


module DrupalMuncher
  def create_connection(db)
    ActiveRecord::Base.establish_connection(db.merge(:adapter => "mysql"))
    ActiveRecord::Base.connection()
  end

  class Node < ActiveRecord::Base
    set_primary_key :nid
    set_table_name :node
    has_many :node_revisions, :foreign_key => :nid

    attr_accessor :body, :new_node_revision

    def self.inheritance_column; 'none'; end

    def self.of_type(klass)
      find(:all, :conditions => {:type => klass})
    end

    def before_validation_on_create
      self.uid = 1          if self.uid == 0
      self.status = 1       if self.status == 0
      self.comment ||= 0
      self.promote = 1      if self.promote == 0
      self.created = Time.now.to_s
    end

    def before_save
      if body
         self.node_revisions.build({:body => body,
              :title => self.title,
              :uid => 1, :format => 2})
      end
    end
    
    def path
      "node/#{nid}"
    end
  end

  class NodeRevision < ActiveRecord::Base
    set_primary_key :vid
    belongs_to :node, :foreign_key => :nid

    def after_initialize
      self.timestamp = Time.now.to_i
    end

    def after_save
      self.node.update_attribute(:vid, vid) unless node.vid == vid
    end
  end

  class UrlAlias < ActiveRecord::Base
    set_primary_key :pid
    set_table_name :url_alias
    
    def before_save
      self.src.sub!(/^\//,'')
      self.dst.sub!(/^\//,'')
    end
    #src  ->  ie: node/132
    #dst  ->  alias
  end


end

