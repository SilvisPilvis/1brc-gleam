import gleam/bit_array
import gleam/dict
import gleam/float
import gleam/int
import gleam/io
import gleeunit
import gleeunit/should
import main
import priv/stream_binary

pub fn main() {
  gleeunit.main()
}

// Rīga=-88.3/19.6/99.1
// Tallinn=-91.5/3.4/88.8
// Vilnius=-99.0/8.9/92.8

pub fn read_and_calculate_test() {
  io.println("read_and_calculate_test")
  let path: String = "testing.txt"

  let sd = main.read_file_to_struct(path)
  case sd {
    Ok(station_data) -> {
      // Riga
      let tallinn = dict.get(station_data, "Rīga")
      case tallinn {
        Ok(riga) -> {
          let avg = float.to_precision(riga.sum /. int.to_float(riga.count), 1)

          riga.min |> should.equal(-88.3)
          avg |> should.equal(19.6)
          riga.max |> should.equal(99.1)
        }
        Error(Nil) -> should.fail()
      }
      // Tallinn
      let vilnius = dict.get(station_data, "Tallinn")
      case vilnius {
        Ok(tallinn) -> {
          let avg =
            float.to_precision(tallinn.sum /. int.to_float(tallinn.count), 1)

          tallinn.min |> should.equal(-91.5)
          avg |> should.equal(3.4)
          tallinn.max |> should.equal(88.8)
        }
        Error(Nil) -> should.fail()
      }
      // Vilnius
      let vilnius = dict.get(station_data, "Vilnius")
      case vilnius {
        Ok(vilnius) -> {
          let avg =
            float.to_precision(vilnius.sum /. int.to_float(vilnius.count), 1)

          vilnius.min |> should.equal(-99.0)
          avg |> should.equal(8.9)
          vilnius.max |> should.equal(92.8)
        }
        Error(Nil) -> should.fail()
      }
    }
    Error(Nil) -> should.fail()
  }
}

pub fn ffi_read_test() {
  io.println("\nffi_read_test")
  // Open file and read 10 bytes as binary
  let binary_stream = stream_binary.open("testing.txt")
  case binary_stream {
    // If file is opened successfully
    Ok(stream) -> {
      // Read 10 bytes from the file
      case stream_binary.read(stream, 10) {
        // If data is read successfully
        Ok(data) -> {
          // Convert binary to string
          case bit_array.to_string(data) {
            Ok(text) -> {
              // Print the read data
              io.println("Read: " <> text)
            }
            // If conversion to string fails
            Error(_) -> {
              io.println("Failed to convert binary to string")
              should.fail()
            }
          }
        }
        // If failed to read data
        Error(reason) -> {
          // Print the reason
          io.println("Error reading file: " <> reason)
          should.fail()
        }
      }

      // Close the file
      case stream_binary.close(stream) {
        // If file is closed successfully (returns Ok(Nil))
        Ok(Nil) -> io.println("File closed successfully")
        // If failed to close the file
        Error(reason) -> {
          io.println("Failed to close file: " <> reason)
          should.fail()
        }
      }
    }
    // If failed to open the file
    Error(reason) -> {
      // Print the reason
      io.println("Error opening file: " <> reason)
      should.fail()
    }
  }
}
