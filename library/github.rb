module GitHub

  OWNER = [nil, ''].include?(ENV['CREW_OWNER']) ? 'crystax' : ENV['CREW_OWNER']

  STAGING_REPO_NAME  = 'android-crew-staging'
  STAGING_RELEASE_ID = '7122171'

  STAGING_SSH_URL       = "git@github.com:#{OWNER}/#{STAGING_REPO_NAME}.git"
  STAGING_HTTPS_URL     = "https://github.com/#{OWNER}/#{STAGING_REPO_NAME}.git"
  STAGING_DOWNLOAD_BASE = "https://github.com/#{OWNER}/#{STAGING_REPO_NAME}/releases/download/staging"
end
