require 'geocoder'
require 'i18n'
require 'open-uri'
require 'parallel'
require 'redcarpet'

I18n.available_locales = [:pl]
I18n.locale = :pl
I18n.load_path += ['./locale.yml']

config = if ENV.has_key?('BING_API_KEY')
    { :lookup => :bing, :api_key => ENV['BING_API_KEY'] }
else
    { :lookup => :yandex }
end

Geocoder.configure(config)

markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

powiats = Parallel.map(1..379, :in_threads => 32) { |idx|
    JSON.parse(open("https://api.mojepanstwo.pl/dane/powiaty/#{idx}/geojson").read)
}

lines = ARGF
    .each_line
    .map(&:rstrip)
    .slice_when { |before, after| !after.match(/^\s/) }
    .to_a

coordinates = lines.map { |line|
    city, country = line[0].sub(/\*/, "").split(',').map(&:strip)
    country ||= 'Poland'
    marker_color = if line[0].start_with?('*') then "#b7167f" else "#5c0b40" end
    description = markdown.render(line
        .drop(1)
        .map { |line| line[1..-1] }
        .join('\n'))
    Geocoder.search("#{city}, #{country}").map { |result|
        [result.coordinates.reverse, {
            :title => result.city,
            :description => if description.empty? then nil else description end,
            "marker-color" => marker_color
        }.reject { |k, v| v.nil? }]
    }.first
}

coordinates = Hash[ *coordinates.reject(&:nil?).flatten(1) ]

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
    } + powiats
})
