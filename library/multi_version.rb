module MultiVersion

  def releases_for_upgrade
    releases.reduce([]) { |acc, r| (r.installed? and (r.installed_crystax_version < r.crystax_version)) ? acc << r : acc }
  end
end
