pub type Permit

// pub type Atom

@external(erlang, "stream_binary", "open")
pub fn open(path: String) -> Result(Permit, String)

@external(erlang, "stream_binary", "read")
pub fn read(permit: Permit, size: Int) -> Result(BitArray, String)

@external(erlang, "stream_binary", "close")
pub fn close(permit: Permit) -> Result(Nil, String)
