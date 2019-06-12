require 'securerandom'

class KeyServer
  attr_reader :keys
  attr_reader :free
  attr_reader :deleted
  $TTL = 300
  $KEY_TIMEOUT = 60
  
  def initialize
    @keys = Hash.new
    @free = Hash.new
    @deleted = Set.new
  end

  def get_random_string 
    random_string = SecureRandom.hex
  end
  
  def generate_keys length
    while @free.length < length do
      key = get_random_string 
      next if @keys[key] != nil && @deleted.has_key?(key)
        @keys[key] = {
          keep_alive_stamp: Time.now.to_i,
          assigned_stamp: 0
        }
      @free[key] = 1
    end
    return @keys.keys
  end
  
  def get_key
    key = nil
    if @free.length > 0 
      key = @free.shift[0]
      @keys[key][:assigned_stamp] = Time.now.to_i
    end
    key
  end

  def release_key key
    return false if @keys[key] == nil || @keys[key][:assigned_stamp] == 0
    @keys[key][:assigned_stamp] = 0
    @free[key] = 1
    return true
  end
  
  def delete_key key
    return false if @keys[key] == nil
    @keys.delete key
    @free.delete key
    @deleted.add(key)
    return true
  end
  
  def refresh_key key
    return false if @keys[key] == nil || Time.now.to_i - @keys[key][:keep_alive_stamp] >= $TTL
    @keys[key][:keep_alive_stamp] = Time.now.to_i
    return true
  end

  def cleanup 
    @keys.each { |key, val|
      if Time.now.to_i - @keys[key][:keep_alive_stamp] >= $TTL
        delete_key key
      elsif Time.now.to_i - @keys[key][:assigned_stamp] >= $KEY_TIMEOUT
        release_key key
      end
    }
  end
end