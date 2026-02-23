class Meowpass < Formula
  desc "Secure, phrase-based password generator using cat names and Kolmogorov complexity analysis"
  homepage "https://github.com/SpaceTrucker2196/MeowPassword"
  url "https://github.com/SpaceTrucker2196/MeowPassword.git", tag: "V1.0.0"
  license "MIT"

  depends_on xcode: ["14.0", :build]

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/meowpass"
  end

  test do
    assert_match "PASS", shell_output("#{bin}/meowpass --test")
  end
end
