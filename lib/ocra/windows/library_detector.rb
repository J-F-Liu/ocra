
module Ocra
  module LibraryDetector
    def LibraryDetector.loaded_dlls
      require 'Win32API'

      enumprocessmodules = Win32API.new('psapi', 'EnumProcessModules', ['L','P','L','P'], 'B')
      getmodulefilename = Win32API.new('kernel32', 'GetModuleFileName', ['L','P','L'], 'L')
      getcurrentprocess = Win32API.new('kernel32', 'GetCurrentProcess', ['V'], 'L')

      bytes_needed = 4 * 32
      module_handle_buffer = nil
      process_handle = getcurrentprocess.call()
      loop do
        module_handle_buffer = "\x00" * bytes_needed
        bytes_needed_buffer = [0].pack("I")
        r = enumprocessmodules.call(process_handle, module_handle_buffer, module_handle_buffer.size, bytes_needed_buffer)
        bytes_needed = bytes_needed_buffer.unpack("I")[0]
        break if bytes_needed <= module_handle_buffer.size
      end
      
      handles = module_handle_buffer.unpack("I*")
      handles.select { |handle| handle > 0 }.map do |handle|
        str = "\x00" * 256
        modulefilename_length = getmodulefilename.call(handle, str, str.size)
        Ocra.Pathname(str[0,modulefilename_length])
      end
    end

    def LibraryDetector.detect_dlls
      loaded = loaded_dlls
      exec_prefix = Host.exec_prefix
      loaded.select { |path| path.subpath?(exec_prefix) && path.basename.ext?('.dll') && path.basename != Host.libruby_so }
    end
  end
end