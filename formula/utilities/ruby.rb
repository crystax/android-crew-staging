class Ruby < Formula
  include Utility

  homepage "https://www.ruby-lang.org/"

  release version: '2.2.2', build_number: 1, sha256: '0'

  def link(ndk_dir, platform, ver, bldnum)
    FileUtils.cd(dest_dir(ndk_dir, platform, 'bin')) do
      prog_ruby = exec_name(platform, 'ruby')
      FileUtils.rm_rf prog_ruby
      FileUtils.ln_s File.join(src_dir(ver, bldnum, 'bin'), prog_ruby), prog_ruby
      FileUtils.rm_rf 'rspec'
      FileUtils.ln_s File.join(src_dir(ver, bldnum, 'bin'), 'rspec'), 'rspec'
    end
    FileUtils.cd(dest_dir(ndk_dir, platform, 'lib')) do
      prog_ruby = exec_name(platform, 'ruby')
      FileUtils.rm_rf 'ruby'
      FileUtils.ln_s File.join(src_dir(ver, bldnum, 'lib'), prog_ruby), 'ruby'
    end
  end
end
