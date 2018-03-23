def process_compiler_args(compiler, build_options, stl_lib_name, cflags, ldflags)
  # compiler can contaion some required options
  args = compiler.split(' ')
  compiler = args[0]
  args = args[1, args.size]

  # add arguments given to wrapper scripts
  args += ARGV

  # todo: handle build options and other parameters
  fix_soname   args, build_options[:wrapper_translate_sonames]
  remove_args  args, build_options[:wrapper_remove_args]
  replace_args args, build_options[:wrapper_replace_args]

  if compiling? args
    args = cflags.split(' ') + args
  else
    args = ldflags[:before].split(' ') + args + ldflags[:after].split(' ')
    args.delete('-pie') if linking_so?(args)
  end

  #puts "compiler: #{compiler}"
  #puts "args:     #{args}"
  #end

  [compiler, args]
end

def fix_soname(args, translation_table)
  return if translation_table.empty?

  args.each_index do |i|
    case args[i]
    when '-Wl,-soname', '-Wl,-h', '-install_name'
      puts "args[#{i}] = #{args[i]}"
      puts "args[#{i+1}] = #{args[i+1]}"
      new_soname = translation_table[extract_libname(args[i+1])]
      if new_soname
        args[i] = '-Wl,-soname'
        args[i+1] = "-Wl,#{new_soname}.so"
        break
      end
    when /-Wl,-soname[,=]lib.*|-Wl,-h,lib.*/
      puts "args[#{i}] = #{args[i]}"
      new_soname = translation_table[extract_libname(args[i])]
      if new_soname
        args[i] = "-Wl,-soname=#{new_soname}.so"
        break
      end
    end
  end
end

def extract_libname(s)
  m = /.*(lib.*)/.match(s)
  if m
    libname = "#{m[1]}"
    return libname
  end

  raise "do not know how to extract libname: #{s}"
end

  #   if next_param_is_libname
  #     puts "args[#{i}] = #{args[i]}"
  #     libname = extract_libname(args[i])
  #     args[i] = "-Wl,#{libname}.so"
  #     next_param_is_libname = false
  #   else
  #   end
  # end

  # building_so_lib = false
  # args.each_index do |i|
  #   if args[i] == '-o'
  #     building_so_lib = true if args[i+1].end_with?('.so')
  #     break
  #   end
  # end

  # if building_so_lib
  #   args.each_index do |i|
  #     case args[i]
  #     when '-Wl,-soname', '-Wl,-h', '-install_name'
  #       args[i] = nil
  #       args[i+1] = nil
  #     when /-Wl,-soname[,=]lib.*|-Wl,-h,lib.*/
  #       args[i] = nil
  #     end
  #   end
  #   args.compact!
  # end

  # next_param_is_libname = false
  # args.each_index do |i|
  #   if next_param_is_libname
  #     puts "args[#{i}] = #{args[i]}"
  #     libname = extract_libname(args[i])
  #     args[i] = "-Wl,#{libname}.so"
  #     next_param_is_libname = false
  #   else
  #     case args[i]
  #     when '-Wl,-soname', '-Wl,-h', '-install_name'
  #       args[i] = '-Wl,-soname'
  #       next_param_is_libname = true
  #     when /-Wl,-soname[,=]lib.*|-Wl,-h,lib.*/
  #       puts "args[#{i}] = #{args[i]}"
  #       libname = extract_libname(args[i])
  #       args[i] = "-Wl,-soname=#{libname}.so"
  #     end
  #   end
  # end


def remove_args(args, toremove)
  toremove.each { |e| args.delete(e) }
end

def replace_args(args, toreplace)
  args.each_index do |i|
    opt = args[i]
    args[i] = toreplace[opt] if toreplace.has_key? opt
  end
end

def compiling?(args)
  args.include?('-c') or args.include?('-emit-pth')
end

def linking_so?(args)
  ind = args.find_index('-o')
  if ind == nil
    false
  else
    # look for: *.so or *.so.*
    args[ind+1] =~ /.*\.(so$|so\..*)/
  end
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
