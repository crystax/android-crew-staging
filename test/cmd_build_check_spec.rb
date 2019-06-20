# must be first file included
require_relative 'spec_helper.rb'


describe "crew build-check" do
  before(:all) do
    environment_init
    ndk_init
  end

  before(:each) do
    clean_hold
    clean_cache
    repository_init
    repository_clone
  end

  context 'when run without --show-bad-only option' do

    context 'no names specified' do
      it 'outputs OK for all installed utils' do
        crew 'build-check'
        expect(result).to eq(:ok)
        got = out.split("\n")
        exp = [/host\/binutils:/,
               /[ ]+.*_\d+: OK/,
               /host\/bzip2:/,
               /[ ]+.*_\d+: OK/,
               /host\/cloog:/,
               /[ ]+.*_\d+: not installed/,
               /host\/cloog-old:/,
               /[ ]+.*_\d+: not installed/,
               /host\/curl:/,
               /[ ]+.*_\d+: OK/,
               /host\/expat:/,
               /[ ]+.*_\d+: not installed/,
               /host\/gcc:/,
               /[ ]+.*_\d+: OK/,
               /host\/gmp:/,
               /[ ]+.*_\d+: not installed/,
               /host\/isl:/,
               /[ ]+.*_\d+: not installed/,
               /host\/isl-old:/,
               /[ ]+.*_\d+: not installed/,
               /host\/libarchive:/,
               /[ ]+.*_\d+: OK/,
               /host\/libedit:/,
               /[ ]+.*_\d+: not installed/,
               /host\/libgit2:/,
               /[ ]+.*_\d+: OK/,
               /host\/libssh2:/,
               /[ ]+.*_\d+: OK/,
               /host\/llvm:/,
               /[ ]+.*_\d+: OK/,
               /host\/make:/,
               /[ ]+.*_\d+: OK/,
               /host\/mpc:/,
               /[ ]+.*_\d+: not installed/,
               /host\/mpfr:/,
               /[ ]+.*_\d+: not installed/,
               /host\/nawk:/,
               /[ ]+.*_\d+: OK/,
               /host\/ndk-base:/,
               /[ ]+.*_\d+: OK/,
               /host\/ndk-depends:/,
               /[ ]+.*_\d+: OK/,
               /host\/ndk-stack:/,
               /[ ]+.*_\d+: OK/,
               /host\/openssl:/,
               /[ ]+.*_\d+: OK/,
               /host\/ppl:/,
               /[ ]+.*_\d+: not installed/,
               /host\/python:/,
               /[ ]+.*_\d+: OK/,
               /host\/ruby:/,
               /[ ]+.*_\d+: OK/,
               /host\/xz:/,
               /[ ]+.*_\d+: OK/,
               /host\/yasm:/,
               /[ ]+.*_\d+: OK/,
               /host\/zlib:/,
               /[ ]+.*_\d+: OK/
              ]
        expect(got.size).to eq(exp.size)
        got.each_with_index { |g, i| expect(g).to match(exp[i]) }
      end
    end

    context 'one package name specified' do

      context 'package has no build info' do
        it 'outputs OK' do
          repository_add_formula :target, 'build_check_package-1.rb:build_check_package.rb'
          repository_clone
          crew_checked 'install build-check-package'
          crew 'build-check build-check-package'
          expect(result).to eq(:ok)
          expect(out.split("\n")).to eq(['target/build-check-package: ',
                                         '  1_1: OK'
                                        ])
        end
      end

      context 'package has empty build info' do
        it 'outputs OK' do
          repository_add_formula :target, 'build_check_package-2.rb:build_check_package.rb'
          repository_clone
          crew_checked 'install build-check-package'
          crew 'build-check build-check-package'
          expect(result).to eq(:ok)
          expect(out.split("\n")).to eq(['target/build-check-package: ',
                                         '  2_1: OK'
                                        ])
        end
      end

      context 'package was built against non existing formula' do
        it 'outputs bad names line with non existing package name on it' do
          repository_add_formula :target, 'build_check_package-3.rb:build_check_package.rb'
          repository_clone
          crew_checked 'install build-check-package'
          crew 'build-check build-check-package'
          expect(result).to eq(:ok)
          expect(out.split("\n")).to eq(['target/build-check-package: ',
                                         '  3_1: build with bad build dependencies:',
                                         '    not existing formulas: target/build-check-dep-package:1.0.0_1',
                                         '    build info does not correspond to formula\'s dependencies:',
                                         '      build info:   target/build-check-dep-package:1.0.0_1',
                                         '      dependencies: '
                                        ])
        end
      end

      context 'package was built against non existing release of an existing formula' do
        it  'outputs bad releases line with non existing release on it' do
          repository_add_formula :target, 'build_check_package-4.rb:build_check_package.rb', 'build_check_dep_package-1.rb:build_check_dep_package.rb'
          repository_clone
          crew_checked 'install build-check-package'
          crew 'build-check build-check-package'
          expect(result).to eq(:ok)
          expect(out.split("\n")).to eq(['target/build-check-package: ',
                                         '  4_1: build with bad build dependencies:',
                                         '    not existing releases: target/build-check-dep-package:1.0.0_1'
                                        ])
        end
      end

      context 'package was built against an old release of an existing formula and there is newer release' do
        it 'outputs new releases line with the obsolete release on it' do
          repository_add_formula :target, 'build_check_package-5.rb:build_check_package.rb', 'build_check_dep_package-2.rb:build_check_dep_package.rb'
          repository_clone
          crew_checked 'install build-check-package'
          crew 'build-check build-check-package'
          expect(result).to eq(:ok)
          expect(out.split("\n")).to eq(['target/build-check-package: ',
                                         '  5_1: build with bad build dependencies:',
                                         '    have newer releases: target/build-check-dep-package:1.0.0_1'
                                        ])
        end
      end

      context 'package was built against an old release and there is newer release that not matches required version' do
        it 'outputs OK' do
          repository_add_formula :target, 'build_check_package-6.rb:build_check_package.rb', 'build_check_dep_package-3.rb:build_check_dep_package.rb'
          repository_clone
          crew_checked 'install build-check-package'
          crew 'build-check build-check-package'
          expect(result).to eq(:ok)
          expect(out.split("\n")).to eq(['target/build-check-package: ',
                                         '  6_1: OK'
                                        ])
        end
      end

      context 'package was built against an old release and there is newer release that matches required version' do
        it 'outputs new releases line with the obsolete release on it' do
          repository_add_formula :target, 'build_check_package-7.rb:build_check_package.rb', 'build_check_dep_package-4.rb:build_check_dep_package.rb'
          repository_clone
          crew_checked 'install build-check-package'
          crew 'build-check build-check-package'
          expect(result).to eq(:ok)
          expect(out.split("\n")).to eq(['target/build-check-package: ',
                                         '  7_1: build with bad build dependencies:',
                                         '    have newer releases: target/build-check-dep-package:1.0.0_1'
                                        ])
        end
      end

      context 'package has dependency but empty build info' do
        it 'outputs info about bad build info' do
          repository_add_formula :target, 'build_check_package-8.rb:build_check_package.rb', 'build_check_dep_package-1.rb:build_check_dep_package.rb'
          repository_clone
          crew_checked 'install build-check-package'
          crew 'build-check build-check-package'
          expect(result).to eq(:ok)
          expect(out.split("\n")).to eq(['target/build-check-package: ',
                                         '  8_1: build with bad build dependencies:',
                                         '    build info does not correspond to formula\'s dependencies:',
                                         '      build info:   ',
                                         '      dependencies: target/build-check-dep-package'
                                        ])
        end
      end

      context 'package has two dependencies with the same name and different versions' do

        context 'package was built against actual versions of the both dependencies' do
          it 'outputs OK line' do
            repository_add_formula :target, 'build_check_package-9.rb:build_check_package.rb', 'build_check_dep_package-3.rb:build_check_dep_package.rb'
            repository_clone
            crew_checked 'install build-check-package'
            crew 'build-check build-check-package'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(['target/build-check-package: ',
                                           '  9_1: OK'
                                          ])
          end
        end

        context 'package was build against old version of the first dependecy' do
          it 'outputs about non existing release of the first dependency' do
            repository_add_formula :target, 'build_check_package-9.rb:build_check_package.rb', 'build_check_dep_package-5.rb:build_check_dep_package.rb'
            repository_clone
            crew_checked 'install build-check-package'
            crew 'build-check build-check-package'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(['target/build-check-package: ',
                                         '  9_1: build with bad build dependencies:',
                                         '    not existing releases: target/build-check-dep-package:1.0.0_1'
                                          ])
          end
        end

        context 'package was build against old version of the second dependecy' do
          it 'outputs about non existing release of the second dependency' do
            repository_add_formula :target, 'build_check_package-9.rb:build_check_package.rb', 'build_check_dep_package-6.rb:build_check_dep_package.rb'
            repository_clone
            crew_checked 'install build-check-package'
            crew 'build-check build-check-package'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(['target/build-check-package: ',
                                         '  9_1: build with bad build dependencies:',
                                         '    not existing releases: target/build-check-dep-package:2.0.0_1'
                                          ])
          end
        end

        context 'package was build against old versions of the both dependecies' do
          it 'outputs about non existing releases of the both dependencies' do
            repository_add_formula :target, 'build_check_package-9.rb:build_check_package.rb', 'build_check_dep_package-7.rb:build_check_dep_package.rb'
            repository_clone
            crew_checked 'install build-check-package'
            crew 'build-check build-check-package'
            expect(result).to eq(:ok)
            expect(out.split("\n")).to eq(['target/build-check-package: ',
                                         '  9_1: build with bad build dependencies:',
                                         '    not existing releases: target/build-check-dep-package:1.0.0_1, target/build-check-dep-package:2.0.0_1'
                                          ])
          end
        end
      end
    end

    # todo:
    # context 'one tool name specified' do
    # end
  end

  context 'when run with --show-bad-only option' do

    context 'no arguments specified' do
      it 'outputs nothing' do
        crew 'build-check --show-bad-only'
        expect(result).to eq(:ok)
        expect(out.strip).to eq('')
      end
    end

    context 'one package name specified' do

      context 'package has no build info' do
        it 'outputs nothing' do
          repository_add_formula :target, 'build_check_package-1.rb:build_check_package.rb'
          repository_clone
          crew_checked 'install build-check-package'
          crew 'build-check --show-bad-only build-check-package'
          expect(result).to eq(:ok)
          expect(out.strip).to eq('')
        end
      end

      context 'package has empty build info' do
        it 'outputs nothing' do
          repository_add_formula :target, 'build_check_package-2.rb:build_check_package.rb'
          repository_clone
          crew_checked 'install build-check-package'
          crew 'build-check --show-bad-only build-check-package'
          expect(result).to eq(:ok)
          expect(out.strip).to eq('')
        end
      end

      context 'when package was built against non existing formula' do
        it 'outputs bad names line with non existing package name on it' do
          repository_add_formula :target, 'build_check_package-3.rb:build_check_package.rb'
          repository_clone
          crew_checked 'install build-check-package'
          crew 'build-check --show-bad-only build-check-package'
          expect(result).to eq(:ok)
          expect(out.split("\n")).to eq(['target/build-check-package: ',
                                         '  3_1: build with bad build dependencies:',
                                         '    not existing formulas: target/build-check-dep-package:1.0.0_1',
                                         '    build info does not correspond to formula\'s dependencies:',
                                         '      build info:   target/build-check-dep-package:1.0.0_1',
                                         '      dependencies: '
                                        ])
        end
      end
    end
  end
end
