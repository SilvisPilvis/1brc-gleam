import gleam/dict
import gleam/float
import gleam/int
import gleeunit
import gleeunit/should
import main

pub fn main() {
  gleeunit.main()
}

// Rīga=-88.3/19.6/99.1
// Tallinn=-91.5/3.4/88.8
// Vilnius=-99.0/8.9/92.8

pub fn read_and_calculate_test() {
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
