import Foundation

struct Station: Identifiable, Equatable, Hashable {
    var id: String { name }  // Required for Identifiable conformance

    let name: String
    let streamURL: String
    let statusURL: String
}

let stations = [
    Station(name: "Crimson Hall",
            streamURL: "https://s4.radio.co/s1e0b382a0/listen",
            statusURL: "https://public.radio.co/stations/s1e0b382a0/status"),
    Station(name: "Wizard’s Forest",
            streamURL: "https://streamer.radio.co/s95a101d27/listen",
            statusURL: "https://public.radio.co/stations/s95a101d27/status"),
    Station(name: "Dragon’s Tower",
            streamURL: "https://s4.radio.co/s141f9a810/listen",
            statusURL: "https://public.radio.co/stations/s141f9a810/status")
]

