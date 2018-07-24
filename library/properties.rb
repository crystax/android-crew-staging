require 'json'

module Properties

  FILE = 'properties.json'

  def get_properties(dir)
    propfile = File.join(dir, FILE)
    unless File.exists? propfile
      {}
    else
      JSON.parse(IO.read(propfile), symbolize_names: true)
    end
  end

  def save_properties(prop, dir)
    propfile = File.join(dir, FILE)
    File.open(propfile, "w") { |f| f.puts prop.to_json ; f.flush }
  end
end
