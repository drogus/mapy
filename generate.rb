require 'geocoder'
require 'i18n'

I18n.available_locales = [:pl]
I18n.locale = :pl
I18n.load_path += ['./locale.yml']

Geocoder.configure(:lookup => :yandex)

lines = ARGF.lines.map(&:strip).map { |line| line.split("\t") }.to_a
coordinates = Hash[ *lines.map { |line|
    location = line[0]
    next_meeting = if line[1].nil?
        nil
    else
        localized = I18n.localize(Date.parse(line[1]), :format => "%e %B %Y")
        "Następne spotkanie: #{localized}"
    end
    Geocoder.search(location + ", Poland").map { |result|
        [result.coordinates.reverse, {
            :title => result.city,
            :description => next_meeting
        }.reject { |k, v| v.nil? }]
    }.first
}.reject(&:nil?).flatten(1) ]

puts JSON.pretty_generate({
    :type => "FeatureCollection",
    :features => coordinates.map { |coordinates, properties|
        {
            :type => "Feature",
            :geometry => {
                :type => "Point",
                :coordinates => coordinates
            },
            :properties => properties
        }
    }
})
