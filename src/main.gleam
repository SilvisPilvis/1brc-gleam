import file_streams/file_stream
import file_streams/file_stream_error
import gleam/dict
import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

pub type StationData {
  StationData(sum: Float, count: Int, min: Float, max: Float)
}

pub fn main() -> Nil {
  let path: String = "testing.txt"
  // let path: String = "test.txt"

  let _pid = process.self()
  // echo _pid
  let _subject = process.new_subject()

  let station_data: dict.Dict(String, StationData) = dict.new()

  // Make a thread for each letter of the alphabet
  // Process all Stations that start with `A` on the same thread

  // process.spawn()
  // let pid = process.spawn(fn() { process_stream(file_stream.open_read(path)) })

  let _workers: Int = 16

  // <station>=<min>/<avg>/<max>

  io.println("Trying to open file: " <> path)

  // Try to open the file
  case file_stream.open_read(path) {
    // File not found
    Error(file_stream_error.Enoent) -> io.println("File not found")
    // Print the error
    Error(err) -> io.println("Error: " <> file_stream_error.describe(err))
    // If the file was opened successfully, read the lines
    Ok(stream) -> {
      io.println("File " <> path <> " opened successfully")
      io.println("<station>=<min>/<avg>/<max>")
      process_stream(stream, station_data)
    }
  }
}

/// Convert to string with hardcoded precision (most performant for known precision)
pub fn to_string_one_decimal_positive(value: Float) -> String {
  let rounded = float.to_precision(value, 1)
  float.to_string(rounded)
}

pub fn process_stream(
  stream: file_stream.FileStream,
  station_data: dict.Dict(String, StationData),
) -> Nil {
  case file_stream.read_line(stream) {
    // If we have reached the end of the file
    Error(file_stream_error.Eof) -> {
      // Print the sorted stations
      station_data
      |> dict.to_list
      |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
      |> list.each(fn(station) {
        let avg = { station.1 }.sum /. int.to_float({ station.1 }.count)
        io.println(
          station.0
          <> "="
          <> float.to_string({ station.1 }.min)
          <> "/"
          <> to_string_one_decimal_positive(avg)
          // Fixed: showing average instead of sum
          <> "/"
          <> float.to_string({ station.1 }.max),
        )
      })
    }

    // If there was an error reading the file
    Error(err) -> io.println("Error: " <> file_stream_error.describe(err))

    // Process current line and use recursion to read the next line
    Ok(line) -> {
      // Split once and reuse
      let parts = string.split(line, on: ";")

      case parse_line(parts) {
        Ok(#(station_name, station_temp)) -> {
          let updated_data =
            update_station_data(station_data, station_name, station_temp)
          process_stream(stream, updated_data)
        }
        Error(_) -> {
          // Skip malformed lines and continue processing
          io.println("Warning: Skipping malformed line: " <> line)
          process_stream(stream, station_data)
        }
      }
    }
  }
}

pub fn process_stream_to_struct(
  stream: file_stream.FileStream,
  station_data: dict.Dict(String, StationData),
) -> Result(dict.Dict(String, StationData), Nil) {
  case file_stream.read_line(stream) {
    // If we have reached the end of the file
    Error(file_stream_error.Eof) -> {
      // Print the sorted stations
      station_data
      |> dict.to_list
      |> list.sort(fn(a, b) { string.compare(a.0, b.0) })

      Ok(station_data)
    }

    // If there was an error reading the file
    Error(_err) -> {
      Error(Nil)
    }

    // Process current line and use recursion to read the next line
    Ok(line) -> {
      // Split once and reuse
      let parts = string.split(line, on: ";")

      case parse_line(parts) {
        Ok(#(station_name, station_temp)) -> {
          let updated_data =
            update_station_data(station_data, station_name, station_temp)
          process_stream_to_struct(stream, updated_data)
          // Fixed function name
        }
        Error(_) -> {
          // Skip malformed lines and continue processing
          io.println("Warning: Skipping malformed line: " <> line)
          process_stream_to_struct(stream, station_data)
          // Fixed function name
        }
      }
    }
  }
}

// Helper function to parse a line
fn parse_line(parts: List(String)) -> Result(#(String, Float), Nil) {
  use station_name <- result.try(list.first(parts))
  use temp_str <- result.try(list.last(parts))
  use temp <- result.try(
    temp_str
    |> string.trim
    |> float.parse
    |> result.map_error(fn(_) { Nil }),
  )

  // Validate station name is not empty
  case string.trim(station_name) {
    "" -> Error(Nil)
    valid_name -> Ok(#(valid_name, temp))
  }
}

// Helper function to update station data
fn update_station_data(
  station_data: dict.Dict(String, StationData),
  station_name: String,
  temp: Float,
) -> dict.Dict(String, StationData) {
  case dict.get(station_data, station_name) {
    Ok(existing) -> {
      let updated_station =
        StationData(
          sum: existing.sum +. temp,
          count: existing.count + 1,
          min: float.min(temp, existing.min),
          max: float.max(temp, existing.max),
        )
      dict.insert(station_data, station_name, updated_station)
    }
    Error(Nil) -> {
      dict.insert(
        station_data,
        station_name,
        StationData(sum: temp, count: 1, min: temp, max: temp),
      )
    }
  }
}

pub fn read_file_to_struct(
  path: String,
) -> Result(dict.Dict(String, StationData), Nil) {
  let station_data: dict.Dict(String, StationData) = dict.new()

  // Try to open the file
  case file_stream.open_read(path) {
    // File not found
    Error(file_stream_error.Enoent) -> Error(Nil)
    // Print the error
    Error(_) -> Error(Nil)
    // If the file was opened successfully, read the lines
    Ok(stream) -> {
      let struct = process_stream_to_struct(stream, station_data)
      case struct {
        Ok(station_data) -> Ok(station_data)
        Error(Nil) -> Error(Nil)
      }
    }
  }
}
// pub fn process_stream(
//   stream: file_stream.FileStream,
//   station_data: dict.Dict(String, StationData),
// ) -> Nil {
//   case file_stream.read_line(stream) {
//     // If we have reached the end of the file
//     Error(file_stream_error.Eof) -> {
//       // Print the sorted stations
//       station_data
//       |> dict.to_list
//       |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
//       |> list.each(fn(station) {
//         io.println(
//           station.0
//           <> "="
//           <> float.to_string({ station.1 }.min)
//           <> "/"
//           <> float.to_string({ station.1 }.sum)
//           <> "/"
//           <> float.to_string({ station.1 }.max),
//         )
//       })
//
//       io.println("EOF")
//     }
//     // If there was an error reading the file
//     Error(err) -> io.println("Error: " <> file_stream_error.describe(err))
//     // Process current line and use recursion to read the next line
//     Ok(line) -> {
//       let station_name: String = case
//         string.split(line, on: ";") |> list.first
//       {
//         Ok(station_name) -> station_name
//         Error(Nil) -> {
//           io.println("Error: Station name not found")
//           ""
//         }
//       }
//
//       let station_temp: Float = case
//         string.split(line, on: ";")
//         |> list.last
//       {
//         Ok(last_part) ->
//           case
//             last_part
//             |> string.trim
//             |> float.parse
//           {
//             Ok(temp) -> temp
//             Error(Nil) -> 0.0
//           }
//         Error(Nil) -> 0.0
//       }
//
//       let updated_data = case dict.get(station_data, station_name) {
//         // Station is in hashmap
//         Ok(existing_station) -> {
//           let station =
//             StationData(
//               sum: existing_station.sum +. station_temp,
//               count: existing_station.count + 1,
//               min: float.min(station_temp, existing_station.min),
//               max: float.max(station_temp, existing_station.max),
//             )
//
//           dict.insert(station_data, station_name, station)
//         }
//         // Station is not in hashmap
//         Error(Nil) -> {
//           // Add the station to the hashmap with count = 1 and sum as current value
//           dict.insert(
//             station_data,
//             station_name,
//             StationData(
//               sum: station_temp,
//               count: 1,
//               min: station_temp,
//               max: station_temp,
//             ),
//           )
//         }
//       }
//       // io.print(line)
//       process_stream(stream, updated_data)
//     }
//   }
// }
