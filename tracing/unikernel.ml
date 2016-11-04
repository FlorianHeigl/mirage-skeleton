(* This unikernel is based on tracing documentation:
   https://mirage.io/wiki/profiling
*)

open Lwt.Infix
let target_ip = Ipaddr.V4.of_string_exn "10.0.0.1"

module Main (S: V1_LWT.STACKV4) = struct

  let send_data t =
    let buffer = Io_page.get 1 |> Io_page.to_cstruct in

    S.TCPV4.create_connection t (target_ip, 7001) >>= function
    | `Error _err -> failwith "Connection to port 7001 failed"
    | `Ok flow ->

    let payload = Cstruct.sub buffer 0 1 in
    Cstruct.set_char payload 0 '!';

    S.TCPV4.write flow payload >>= function
    | `Error _ | `Eof -> assert false
    | `Ok () ->

    S.TCPV4.close flow

  let start s =
    let t = S.tcpv4 s in
    Lwt.pick [
      S.listen s;
      send_data t;
    ]

end
