require_relative '../index'


describe KeyServer do
  before :all do
    @key_server = KeyServer.new
  end

  describe '#new' do
    it 'should return a new KeyServer object' do
      expect(@key_server).to be_a KeyServer
    end

    it 'should not return nil' do
      expect(@key_server).not_to be_nil
    end
  end

  describe '#random_string' do
    it 'should return a random string' do
      key = @key_server.get_random_string
      expect(key.length).to eq(32)
    end
  end

  describe '#generate_keys' do
    it 'should return a keys array of given length' do
      keys = @key_server.generate_keys(3)
      expect(keys.size).to eq(3)
    end

    it 'should initialize keep alive timestamp to created time and assigned timestamp' do
       result = true
      @key_server.keys.each do |k, _v|
        result &= @key_server.keys[k].has_key?(:assigned_stamp) && @key_server.keys[k].has_key?(:keep_alive_stamp)
      end
      expect(result).to be_truthy
    end

    it 'should add key to free'  do
      expect(@key_server.free.keys).to  eq(@key_server.keys.keys)
    end
  end

  describe '#get_key' do
    it 'should return a key if available' do
      @key_server.generate_keys(3)
      key = @key_server.get_key
      expect(key).not_to be_nil
    end

    it 'should return nil if no key available' do
      @key_server.get_key until @key_server.free.empty?
      key = @key_server.get_key
      expect(key).to be_nil
    end
  end

  describe '#release_key' do
    it 'returns false if no key found' do
      expect(@key_server.release_key('samplekey')).to be_falsey
    end

    it 'releases a key if given key argument is valid' do
      @key_server.generate_keys(1)
      key = @key_server.get_key
      @key_server.release_key(key)
      expect(@key_server.free).to have_key(key)
    end
  end

  describe '#delete_key' do
    it 'returns false if no key found' do
      expect(@key_server.delete_key('samplekey')).to be_falsey
    end

    it 'deletes a key if given key argument is valid' do
      @key_server.generate_keys(1)
      key = @key_server.get_key
      @key_server.delete_key(key)
      expect(@key_server.keys).not_to have_key(key)
      expect(@key_server.free).not_to have_key(key)
      expect(@key_server.deleted).to include(key)
    end
  end

  describe '#refresh_key' do
    it 'returns false if no key found' do
      expect(@key_server.refresh_key('samplekey')).to be_falsey
    end

    it 'returns false if key is older than 5 minutes' do
      @key_server.generate_keys(1)
      key = @key_server.get_key
      @key_server.keys[key][:keep_alive_stamp] = Time.now.to_i - 301
    
      expect(@key_server.refresh_key(key)).to be_falsey
    end

    it 'updates keep_alive_stamp to current time' do
      @key_server.generate_keys(1)
      key = @key_server.get_key
      @key_server.keys[key][:keep_alive_stamp] = Time.now.to_i - 61
      @key_server.refresh_key(key)
      expect(@key_server.keys[key][:keep_alive_stamp]).to eq(Time.now.to_i)
    end
  end

  describe '#cleanup' do
    it 'delete key if timeout of 5 minutes is  reached' do
      @key_server.generate_keys(1)
      key = @key_server.get_key
      @key_server.keys[key][:keep_alive_stamp] = Time.now.to_i - 301
      @key_server.cleanup
      
      expect(@key_server.deleted.to_a).to include(key)
    end

    it 'release key if timeout of 1 minute is  reached' do
      @key_server.generate_keys(1)
      key = @key_server.get_key
      @key_server.keys[key][:assigned_stamp] = Time.now.to_i - 61
      @key_server.cleanup
      
      expect(@key_server.free.keys).to include(key)
    end
  end
end
