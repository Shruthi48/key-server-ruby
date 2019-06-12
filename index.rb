require "cuba"
require "cuba/safe"
require_relative 'key_server'
require 'rufus-scheduler'

key_server = KeyServer.new

scheduler = Rufus::Scheduler.new

scheduler.every '1s' do
    key_server.cleanup
end

Cuba.plugin Cuba::Safe

Cuba.define do
  # GET requests
  on get do

    # /
    on root do
      res.write "OK"
    end

    #/show 
    on "show" do
      res.write key_server.keys
    end

    #/showFreeKeys
    on "showFreeKeys" do
      res.write(key_server.free.keys)
    end
    
    #/showDeletedKeys
    on "showDeletedKeys" do
      res.write(key_server.deleted.to_a)
    end

    #/key
    on "key" do
      key = key_server.get_key
      if key.nil?
        res.status = 404
        res.write('No free keys. Keys needs to be Generated')
      else
        res.status = 200
        res.write(key)
      end
    end
  end

  on post do
    #/keys
    on "keys" do
      keys = key_server.generate_keys(2)
      res.write(keys)
    end
  end

  on put do
    on "key" do
      #/key/unblock/:id
      on "unblock/:id" do |key|
        if !key_server.release_key(key)
          res.status = 404
          res.write("404 : Oops key #{key} not found")
        else
          res.status = 200
          res.write("Unblock successful for #{key}")
        end
      end

      #/key/keep/:id
      on "keep/:id" do |key|
        if !key_server.refresh_key(key)
          res.status = 404
          res.write("404 : Oops key #{key} not found")
        else
          res.status = 200
          res.write("Keep alive successful for #{key}")
        end
      end
    end
  end
  

  on delete do
    on "key" do
      # DELETE request
      #/key/delete/:id
      on 'delete/:id' do |key|
        if !key_server.delete_key(key)
          res.status = 404
          res.write("404 : Oops key #{key} not found")
        else
          res.status = 200
          res.write("Delete successful for #{key}")
        end
      end
    end
  end
end
