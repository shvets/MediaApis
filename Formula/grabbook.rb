class Grabbook < Formula
  desc "Grabs book from web site by url"
  homepage "https://github.com/shvets/MediaApis"
  url "https://github.com/shvets/MediaApis/archive/1.0.5.tar.gz"
  sha256 "d557df6cd4fe8d984ad96c475b0fb6fc95c763372cd8639fb78276a768bd4269"
  head "https://github.com/shvets/MediaApis.git"

  depends_on :xcode

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end
end
