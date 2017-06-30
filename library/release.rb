class Release

  def initialize(ver = nil, cxver = nil)
    cxver = cxver.to_i if cxver
    @r = { version: ver, crystax_version: cxver }
  end

  def version
    @r[:version]
  end

  def crystax_version
    @r[:crystax_version]
  end

  def installed_crystax_version
    @r[:installed_crystax_version]
  end

  def installed?
    @r[:installed]
  end

  def source_installed?
    @r[:source_installed]
  end

  def installed=(cxver)
    if cxver.is_a? Integer
      @r[:installed] = true
      @r[:installed_crystax_version] = cxver
    elsif cxver == false
      @r[:installed] = false
      @r[:installed_crystax_version] = nil unless @r[:source_installed]
    else
      raise "bad cxver value: #{cxver}; expected integer or 'false'"
    end
  end

  def source_installed=(cxver)
    if cxver.is_a? Integer
      @r[:source_installed] = true
      @r[:installed_crystax_version] = cxver
    elsif cxver == false
      @r[:source_installed] = false
      @r[:installed_crystax_version] = nil unless @r[:installed]
    else
      raise "bad cxver value: #{cxver}; expected integer or 'false'"
    end
  end

  def update(hash)
    # todo: check invariants
    @r.update(hash)
  end

  def match?(r)
    (version == r.version) or (version == nil) or (r.version == nil)
  end

  def to_s
    "#{@r[:version]}_#{@r[:crystax_version]}"
  end
end
