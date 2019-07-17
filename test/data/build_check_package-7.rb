class BuildCheckPackage < Package

  desc "Build Check Package"
  name 'build-check-package'

  depends_on 'dep-package', version: /^1\.0/

  release '7'
end
