cask "elvistelefon" do
  version "1.0.1"
  sha256 "CHECKSUM"

  url "https://github.com/USER/Elvistelefon/releases/download/v#{version}/Elvistelefon-#{version}.dmg"
  name "Elvistelefon"
  desc "Elvis-themed menu bar transcription app using OpenAI Whisper"
  homepage "https://github.com/USER/Elvistelefon"

  depends_on macos: ">= :ventura"

  app "Elvistelefon.app"
end
