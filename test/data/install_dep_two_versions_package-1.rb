class InstallDepTwoVersionsPackage < Package

  desc "Install Dep Two Versions Package"
  name 'install-dep-two-versions-package'

  depends_on 'dep-package', version: /^1\.0/
  depends_on 'dep-package', version: /^2\.0/

  release '1'
end
