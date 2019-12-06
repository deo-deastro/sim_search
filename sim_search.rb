# frozen_string_literal: true

require 'optparse'
require 'mime/types'
require 'phash/text'
require 'phash/audio'
require 'phash/image'
require 'phash/video'

folder     = ARGV[0]
thresholds = { text: 0.5, audio: 0.6, image: 0.6, video: 0.5, binary: 1.0 }

text_group   = { name: :text,   type: 'T', files: [] }
audio_group  = { name: :audio,  type: 'A', files: [] }
image_group  = { name: :image,  type: 'I', files: [] }
video_group  = { name: :video,  type: 'V', files: [] }
binary_group = { name: :binary, type: 'B', files: [] }

file_groups = [text_group, audio_group, image_group, video_group, binary_group]

OptionParser.new do |opts|
  opts.on('-t', '--text   THRESHOLD', Float)
  opts.on('-a', '--audio  THRESHOLD', Float)
  opts.on('-i', '--image  THRESHOLD', Float)
  opts.on('-v', '--video  THRESHOLD', Float)
  opts.on('-b', '--binary THRESHOLD', Float)
end.parse!(into: thresholds)

Dir.glob("#{folder}/*")
   .select { |f| File.file? f }
   .map(&File.method(:realpath)).each do |file|
  case MIME::Types.type_for(file).first.media_type
  when 'text'
    text_group[:files]  << Phash::Text.new(file)
  when 'audio'
    audio_group[:files] << Phash::Audio.new(file)
  when 'image'
    image_group[:files] << Phash::Image.new(file)
  when 'video'
    video_group[:files] << Phash::Video.new(file)
  end
  if MIME::Types.type_for(file).first.binary?
    binary_group[:files] << Phash::Text.new(file)
  end
end

file_groups.each do |group|
  if group[:files].length() >= 2
    group[:files].combination(2) do |f1, f2|
      similarity = f1 % f2
      if similarity >= thresholds[group[:name]]
        puts "#{f1.path}\t#{f2.path}\t#{similarity}\t#{group[:type]}"
      end
    end
  end
end
