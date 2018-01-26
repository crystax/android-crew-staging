module SingleVersion

  def releases_for_upgrade
    urs = []
    lr = releases.last
    if not lr.installed? or (lr.installed_crystax_version < lr.crystax_version)
      urs << lr
    end

    urs
  end
end
