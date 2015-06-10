require 'geocoder'
require 'i18n'

I18n.available_locales = [:pl]
I18n.locale = :pl
I18n.load_path += ['./locale.yml']

Geocoder.configure(:lookup => :yandex)

lines = ARGF
    .lines
    .map(&:rstrip)
    .slice_when { |before, after| !after.start_with?("\t") }
    .to_a
coordinates = Hash[ *lines.map { |line|
    location = line[0].sub(/^*/, "")
    marker_color = if line[0].start_with?('*') then "#AFEEEE" else nil end
    description = line.drop(1).map(&:lstrip).join("<br />")
    Geocoder.search(location + ", Poland").map { |result|
        [result.coordinates.reverse, {
            :title => result.city,
            :description => if description.empty? then nil else description end,
            "marker-color" => marker_color
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
