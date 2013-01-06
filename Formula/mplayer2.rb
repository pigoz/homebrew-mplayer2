require 'formula'

def libav?
  build.include? 'with-libav'
end

def bundle?
  not build.include? 'without-bundle'
end

class DocutilsInstalled < Requirement
  fatal true
  env :userpaths

  def message; <<-EOS.undent
    Docutils is required to install.

    You can install this with:
      sudo easy_install docutils

    You also need to symlink rst2man to some place in your path. For example:
    sudo ln -nfs /usr/local/bin/rst2man.py /usr/local/bin/rst2man
    EOS
  end

  def satisfied?
    which('rst2man') || which('rst2man.py')
  end
end

class GitVersionWriter
  def initialize(downloader)
    @downloader = downloader
  end

  def write
    ohai "Generating VERSION file from Homebrew's git cache"
    File.open('VERSION', 'w') {|f| f.write(git_revision) }
  end

  private
  def git_revision
    `cd #{git_cache} && git describe --match "v[0-9]*" --always`.strip
  end

  def git_cache
    @downloader.cached_location
  end
end

class Mplayer2 < Formula
  head 'git://git.mplayer2.org/mplayer2.git', :using => :git
  homepage 'http://mplayer2.org'

  depends_on 'pkg-config' => :build
  depends_on 'python3' => :build
  depends_on DocutilsInstalled.new => :build

  depends_on 'libbs2b'
  depends_on 'libass'
  depends_on 'mpg123'
  depends_on 'libdvdread'
  depends_on 'libquvi'
  depends_on 'lcms2'

  if libav?
    depends_on 'libav'
  else
    depends_on 'ffmpeg'
  end

  def caveats
    cvts = <<-EOS.undent
      mplayer2 is designed to work best with HEAD versions of ffmpeg/libav.
      If you are noticing problems please try to install the HEAD version of
      ffmpeg with: `brew install --HEAD ffmpeg`
    EOS
    cvts << bundle_caveats if bundle?
    cvts
  end

  option 'with-libav',     'Build against libav instead of ffmpeg.'
  option 'without-bundle', 'Do not create a Mac OSX Application Bundle.'

  def install
    ENV.O1 if ENV.compiler == :llvm
    args = ["--prefix=#{prefix}",
            "--cc=#{ENV.cc}"]

    args << "--enable-macosx-bundle" if bundle?
    args << "--enable-macosx-finder" if bundle?

    GitVersionWriter.new(@downloader).write
    system "./configure", *args
    system "make install"

    mv bin/'mplayer', bin/binary_name
    mv man1/'mplayer.1', man1/(binary_name + '.1')

    if bundle?
      system "make osxbundle"
      prefix.install "#{binary_name}.app"
    end
  end

  private
  def binary_name
    'mplayer2'
  end

  def bundle_caveats; <<-EOS.undent

      #{binary_name}.app installed to:
        #{prefix}

      To link the application to a normal Mac OS X location:
          brew linkapps
      or:
          ln -s #{prefix}/#{binary_name}.app /Applications
      EOS
  end
end
