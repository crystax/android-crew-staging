def process_compiler_args(compiler, build_options, stl_lib_name, cflags, ldflags)
  # compiler can contaion some required options
  args = compiler.split(' ')
  compiler = args[0]
  args = args[1, args.size]

  # add arguments given to wrapper scripts
  args += ARGV

  # todo: handle build options and other parameters
  fix_soname(args) if build_options[:wrapper_fix_soname]
  remove_args(args, build_options[:wrapper_remove_args])
  replace_args(args, build_options[:wrapper_replace_args])

  if linking? args
    args = ldflags[:before].split(' ') + args + ldflags[:after].split(' ')
  else
    args = cflags.split(' ') + args
  end

  if build_options[:debug_compiler_args]
    puts "compiler: #{compiler}"
    puts "args:     #{args}"
  end

  [compiler, args]
end

def fix_soname(args)
  next_param_is_libname = false
  args.each_index do |i|
    if next_param_is_libname
      puts "args[#{i}] = #{args[i]}"
      libname = /.*(lib[^\.]*\.so)/.match(args[i])[1]    # `expr "x$p" : "^x.*\\(lib[^\\.]*\\.so\\)"`
      args[i] = "-Wl,#{libname}"
      next_param_is_libname = false
    else
      case args[i]
      when '-Wl,-soname', '-Wl,-h', '-install_name'
        args[i] = '-Wl,-soname'
        next_param_is_libname = true
      when /-Wl,-soname,lib.*|-Wl,-h,lib.*/
        libname = /.*(lib[^\.]*\.so)/.match(args[i])[1]  #`expr "x$p" : "^x.*\\(lib[^\\.]*\\.so\\)"`
        args[i] = "-Wl,-soname,-l#{libname}"
      end
    end
  end
end

def remove_args(args, toremove)
  toremove.each { |e| args.delete(e) }
end

def replace_args(args, toreplace)
  args.each_index do |i|
    opt = args[i]
    args[i] = toreplace[opt] if toreplace.has_key? opt
  end
end


def linking?(args)
  !args.include?('-c') and !args.include?('-emit-pth')
end


    # File.open(wrapper, "w") do |f|
    #   f.puts '#!/bin/bash'
    #   f.puts 'if echo "$@" | tr \' \' \'\n\' | grep -q -x -e -c; then'
    #   f.puts '    LINKER=no'
    #   f.puts 'elif echo "$@" | tr \' \' \'\n\' | grep -q -x -e -emit-pth; then'
    #   f.puts '    LINKER=no'
    #   f.puts 'else'
    #   f.puts '    LINKER=yes'
    #   f.puts 'fi'
    #   f.puts ''
    #   f.puts 'PARAMS=$@'
    #   if opts = options[:wrapper_replace]
    #     f.puts ''
    #     f.puts 'REPLACED_PARAMS='
    #     f.puts 'for p in $PARAMS; do'
    #     f.puts '    case $p in'
    #     opts.keys.each do |key|
    #       f.puts "        #{key})"
    #       f.puts "            p=#{opts[key]}"
    #       f.puts "            ;;"
    #     end
    #     f.puts '    esac'
    #     f.puts '    REPLACED_PARAMS="$REPLACED_PARAMS $p"'
    #     f.puts 'done'
    #     f.puts 'PARAMS=$REPLACED_PARAMS'
    #   end
    #   if options[:wrapper_fix_soname]
    #     f.puts ''
    #     f.puts 'FIXED_SONAME_PARAMS='
    #     f.puts 'NEXT_PARAM_IS_LIBNAME=no'
    #     f.puts 'for p in $PARAMS; do'
    #     f.puts '    if [ "x$NEXT_PARAM_IS_LIBNAME" = "xyes" ]; then'
    #     f.puts '        LIBNAME=`expr "x$p" : "^x.*\\(lib[^\\.]*\\.so\\)"`'
    #     f.puts '        p="-Wl,$LIBNAME"'
    #     f.puts '        NEXT_PARAM_IS_LIBNAME=no'
    #     f.puts '    else'
    #     f.puts '        case $p in'
    #     f.puts '            -Wl,-soname|-Wl,-h|-install_name)'
    #     f.puts '                p="-Wl,-soname"'
    #     f.puts '                NEXT_PARAM_IS_LIBNAME=yes'
    #     f.puts '                ;;'
    #     f.puts '            -Wl,-soname,lib*|-Wl,-h,lib*)'
    #     f.puts '                LIBNAME=`expr "x$p" : "^x.*\\(lib[^\\.]*\\.so\\)"`'
    #     f.puts '                p="-Wl,-soname,-l$LIBNAME"'
    #     f.puts '                ;;'
    #     f.puts '        esac'
    #     f.puts '    fi'
    #     f.puts '    FIXED_SONAME_PARAMS="$FIXED_SONAME_PARAMS $p"'
    #     f.puts 'done'
    #     f.puts 'PARAMS=$FIXED_SONAME_PARAMS'
    #   end
    #   if options[:wrapper_fix_stl]
    #     f.puts ''
    #     f.puts 'FIXED_STL_PARAMS='
    #     f.puts 'for p in $PARAMS; do'
    #     f.puts '  case $p in'
    #     f.puts '    -lstdc++)'
    #     f.puts "       p=\"-l#{toolchain.stl_lib_name}_shared $p\""
    #     f.puts '       ;;'
    #     f.puts '  esac'
    #     f.puts '  FIXED_STL_PARAMS="$FIXED_STL_PARAMS $p"'
    #     f.puts 'done'
    #     f.puts 'PARAMS=$FIXED_STL_PARAMS'
    #   end
    #   f.puts ''
    #   f.puts 'if [ "x$LINKER" = "xyes" ]; then'
    #   f.puts "    PARAMS=\"#{ldflags[:before]} $PARAMS #{ldflags[:after]}\""
    #   f.puts 'else'
    #   f.puts "    PARAMS=\"#{cflags} $PARAMS\""
    #   f.puts 'fi'
    #   f.puts ''
    #   f.puts "exec #{compiler} $PARAMS"
    # end
    # FileUtils.chmod "a+x", wrapper
  # end
