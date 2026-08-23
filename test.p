program testconst(output);
(* version = 1.05; (* of testconst.p 2015 Nov 17 *)
procedure callme;
const
  pi = 3.14;
begin
  writeln(output,'callme pi =', pi:4:2);
end;
begin
  writeln(output,'testconst');
  callme;
end.
