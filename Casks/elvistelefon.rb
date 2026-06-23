cask "elvistelefon" do
  version "1.1.0"
  sha256 "7fba974bc87fe43b60479b03cbebbd708dc2557de4d86d0fc89dc5391ef66b40"

  url "https://github.com/nicowenterodt/elvistelefon/releases/download/v#{version}/Elvistelefon-#{version}.dmg"
  name "Elvistelefon"
  desc "Elvis-themed menu bar app for on-device Whisper transcription"
  homepage "https://github.com/nicowenterodt/elvistelefon"

  depends_on macos: ">= :ventura"

  app "Elvistelefon.app"
end
