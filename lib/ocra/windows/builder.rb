module Ocra

  # Utility class that produces the actual executable. Opcodes
  # (createfile, mkdir etc) are added by invoking methods on an
  # instance of OcraBuilder.
  class Builder

    Signature = [0x41, 0xb6, 0xba, 0x4e]
    OP_END = 0
    OP_CREATE_DIRECTORY = 1
    OP_CREATE_FILE = 2
    OP_CREATE_PROCESS = 3
    OP_DECOMPRESS_LZMA = 4
    OP_SETENV = 5
    OP_POST_CREATE_PROCESS = 6
    OP_ENABLE_DEBUG_MODE = 7
    OP_CREATE_INST_DIRECTORY = 8

    def initialize(path, windowed)
      @paths = {}
      @files = {}
      File.open(path, "wb") do |ocrafile|
        image = nil
        if windowed
          image = Ocra.stubwimage
        else
          image = Ocra.stubimage
        end

        unless image
          Ocra.fatal_error "Stub image not available"
        end
        ocrafile.write(image)
      end

      if Ocra.icon_filename
        system Ocra.ediconpath, path, Ocra.icon_filename
      end

      opcode_offset = File.size(path)

      File.open(path, "ab") do |ocrafile|
        if Ocra.lzma_mode
          @of = ""
        else
          @of = ocrafile
        end

        if Ocra.debug
          Ocra.msg("Enabling debug mode in executable")
          ocrafile.write([OP_ENABLE_DEBUG_MODE].pack("V"))
        end

        createinstdir Ocra.debug_extract, !Ocra.debug_extract, Ocra.chdir_first

        yield(self)

        if Ocra.lzma_mode and not Ocra.inno_script
          begin
            File.open("tmpin", "wb") { |tmp| tmp.write(@of) }
            Ocra.msg "Compressing #{@of.size} bytes"
            system("\"#{Ocra.lzmapath}\" e tmpin tmpout 2>NUL") or fail
            compressed_data = File.open("tmpout", "rb") { |tmp| tmp.read }
            ocrafile.write([OP_DECOMPRESS_LZMA, compressed_data.size, compressed_data].pack("VVA*"))
          ensure
            File.unlink("tmpin") if File.exist?("tmpin")
            File.unlink("tmpout") if File.exist?("tmpout")
          end
        end

        ocrafile.write([OP_END].pack("V"))
        ocrafile.write([opcode_offset].pack("V")) # Pointer to start of opcodes
        ocrafile.write(Signature.pack("C*"))
      end

      if Ocra.inno_script
        begin
          iss = File.read(Ocra.inno_script) + "\n\n"

          iss << "[Dirs]\n"
          @paths.each_key do |p|
            iss << "Name: \"{app}/#{p}\"\n"
          end
          iss << "\n"

          iss << "[Files]\n"
          path_escaped = path.to_s.gsub('"', '""')
          iss << "Source: \"#{path_escaped}\"; DestDir: \"{app}\"\n"
          @files.each do |tgt, src|
            src_escaped = src.to_s.gsub('"', '""')
            target_dir_escaped = Pathname.new(tgt).dirname.to_s.gsub('"', '""')
            iss << "Source: \"#{src_escaped}\"; DestDir: \"{app}/#{target_dir_escaped}\"\n"
          end
          iss << "\n"

          Ocra.verbose_msg "### INNOSETUP SCRIPT ###\n\n#{iss}\n\n"

          f = File.open("ocratemp.iss", "w")
          f.write(iss)
          f.close()

          iscc_cmd = ["iscc"]
          iscc_cmd << "/Q" unless Ocra.verbose
          iscc_cmd << "ocratemp.iss"
          Ocra.msg "Running InnoSetup compiler ISCC"
          result = system(*iscc_cmd)
          if not result
            case $?
              when 0 then raise RuntimeError.new("ISCC reported success, but system reported error?")
              when 1 then raise RuntimeError.new("ISCC reports invalid command line parameters")
              when 2 then raise RuntimeError.new("ISCC reports that compilation failed")
              else raise RuntimeError.new("ISCC failed to run. Is the InnoSetup directory in your PATH?")
            end
          end
        rescue Exception => e
          Ocra.fatal_error("InnoSetup installer creation failed: #{e.message}")
        ensure
          File.unlink("ocratemp.iss") if File.exist?("ocratemp.iss")
          File.unlink(path) if File.exist?(path)
        end
      end
    end

    def mkdir(path)
      return if @paths[path.to_path.downcase]
      @paths[path.to_path.downcase] = true
      Ocra.verbose_msg "m #{showtempdir path}"
      unless Ocra.inno_script # The directory will be created by InnoSetup with a [Dirs] statement
        @of << [OP_CREATE_DIRECTORY, path.to_native].pack("VZ*")
      end
    end

    def ensuremkdir(tgt)
      tgt = Ocra.Pathname(tgt)
      return if tgt.to_path == "."
      if not @paths[tgt.to_posix.downcase]
        ensuremkdir(tgt.dirname)
        mkdir(tgt)
      end
    end

    def createinstdir(next_to_exe = false, delete_after = false, chdir_before = false)
      unless Ocra.inno_script # Creation of installation directory will be handled by InnoSetup
        @of << [OP_CREATE_INST_DIRECTORY, next_to_exe ? 1 : 0, delete_after ? 1 : 0, chdir_before ? 1 : 0].pack("VVVV")
      end
    end

    def createfile(src, tgt)
      return if @files[tgt]
      @files[tgt] = src
      src, tgt = Ocra.Pathname(src), Ocra.Pathname(tgt)
      ensuremkdir(tgt.dirname)
      str = File.open(src, "rb") { |file| file.read }
      Ocra.verbose_msg "a #{showtempdir tgt}"
      unless Ocra.inno_script # InnoSetup will install the file with a [Files] statement
        @of << [OP_CREATE_FILE, tgt.to_native, str.size, str].pack("VZ*VA*")
      end
    end

    def createprocess(image, cmdline)
      Ocra.verbose_msg "l #{showtempdir image} #{showtempdir cmdline}"
      @of << [OP_CREATE_PROCESS, image.to_native, cmdline].pack("VZ*Z*")
    end

    def postcreateprocess(image, cmdline)
      Ocra.verbose_msg "p #{showtempdir image} #{showtempdir cmdline}"
      @of << [OP_POST_CREATE_PROCESS, image.to_native, cmdline].pack("VZ*Z*")
    end

    def setenv(name, value)
      Ocra.verbose_msg "e #{name} #{showtempdir value}"
      @of << [OP_SETENV, name, value].pack("VZ*Z*")
    end

    def close
      @of.close
    end

    def showtempdir(x)
      x.to_s.gsub(TEMPDIR_ROOT, "<tempdir>")
    end
    
  end # class Builder
end