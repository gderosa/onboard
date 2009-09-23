# My custom, proposed interoperability policy...

# ... givin' up some performance...

class MySimpleFreshClass
  attr_reader :data

  def initialize(h) 
    @data = h
  end

  def set(h)
    ['you', 'may', 'not', 'want', 'all', 'data', 'writeable'].each do |key|
      # I mean, after creation...
      @data[key] = h[key]
    end
  end
  
end

# Objects properties should be convertable to/from hashes (or even strings 
# or numbers, whenever possible).

# Hashes shouldn't be made up of symbols or other Ruby-specific stuff.

# YAML marshaling:

myobj = MySimpleFreshClass.new(
  'property1' => 'something', 'property2' => 'other')

File.open("test.yaml", "w") do |f|
  YAML.dump myobj.data
end

# and unmarshaling:

myobj = MySimpleFreshClass.new YAML.load(File.read "test.yaml")

# So, "test.yaml" file looks pretty to humans and is easily understandable by
# other programming languages. No !ruby/oject things!

class MyAlreadyExistingClass
  def initialize(my, complicated, api) 
    # do something nasty with @many @attributes ...
  end
  def data
    # convert *to* a human-readable, interoperable hash
  end
  def set
    # convert *from* a human-readable, interoperable hash
  end
end


