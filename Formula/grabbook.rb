class Grabbook < Formula
  desc "Grabs book from web site by url"
  homepage "https://github.com/shvets/MediaApis"
  url "https://github.com/shvets/MediaApis/archive/0.1.0.tar.gz"
  sha256 ""
  head "https://github.com/shvets/MediaApis.git"

  depends_on :xcode

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end
end
