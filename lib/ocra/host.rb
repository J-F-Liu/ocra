
module Ocra

# Variables describing the host's build environment.
  module Host
    class << self
      def exec_prefix
        @exec_prefix ||= Ocra.Pathname(RbConfig::CONFIG['exec_prefix'])
      end
      def sitelibdir
        @sitelibdir ||= Ocra.Pathname(RbConfig::CONFIG['sitelibdir'])
      end
      def bindir
        @bindir ||= Ocra.Pathname(RbConfig::CONFIG['bindir'])
      end
      def libruby_so
        @libruby_so ||= Ocra.Pathname(RbConfig::CONFIG['LIBRUBY_SO'])
      end
      def exeext
        RbConfig::CONFIG['EXEEXT'] || ".exe"
      end
      def rubyw_exe
        @rubyw_exe ||= (RbConfig::CONFIG['rubyw_install_name'] || "rubyw") + exeext
      end
      def ruby_exe
        @ruby_exe ||= (RbConfig::CONFIG['ruby_install_name'] || "ruby") + exeext     
      end
      def tempdir
        @tempdir ||= Ocra.Pathname(ENV['TEMP'])
      end
    end
  end

end
