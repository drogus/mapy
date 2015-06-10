require 'geocoder'
require 'i18n'
require 'redcarpet'

I18n.available_locales = [:pl]
I18n.locale = :pl
I18n.load_path += ['./locale.yml']

Geocoder.configure(:lookup => :yandex)

markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

lines = ARGF
    .lines
    .map(&:rstrip)
    .slice_when { |before, after| !after.match(/^\s/) }
    .to_a

coordinates = Hash[ *lines.map { |line|
    location = line[0].sub(/\*/, "")
    marker_color = if line[0].start_with?('*') then "rgb(183, 22, 127)" else "rgb(92, 11, 64)" end
    description = markdown.render(line.drop(1).map(&:lstrip).join('\n'))
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
