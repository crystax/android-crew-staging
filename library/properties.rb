require 'json'

module Properties
  PROPERTIES_FILE = 'properties.json'

  def get_properties(dir)
    propfile = File.join(dir, PROPERTIES_FILE)
    if not File.exists? propfile
      {}
    else
      JSON.parse(IO.read(propfile), symbolize_names: true)
    end
  end

  def save_properties(prop, dir)
    propfile = File.join(dir, PROPERTIES_FILE)
    File.open(propfile, "w") { |f| f.puts prop.to_json }
  end
end
