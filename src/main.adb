with Ada.Text_IO;
with System;
with Interfaces.C;

procedure Main is

   package Pipes is
      type Pipe is private;
      type Get_Result is private;
      function Open_Read (Command : String) return Pipe;
      procedure Close (Stream : Pipe);
      function Get (Stream : Pipe) return Get_Result;
      function End_Of_File (Item : Get_Result) return Boolean;
      function To_Ada (Item : Get_Result) return Character;
   private
      use System;
      use Interfaces.C;
      type Pipe is new Address;
      type Get_Result is new int;
   end;

   package body Pipes is
      function popen (command : char_array; mode : char_array) return Address with Import, Convention => C, External_Name => "popen";
      function pclose (stream : Address) return int with Import, Convention => C, External_Name => "pclose";
      function fgetc (stream : Address) return int with Import, Convention => C, External_Name => "fgetc";
      function Open_Read (Command : String) return Pipe is
         Mode : constant char_array := "r" & nul;
         Result : Address;
      begin
         Result := popen (To_C (Command), Mode);
         if Result = Null_Address then
            raise Program_Error with "popen error";
         end if;
         return Pipe (Result);
      end;
      procedure Close (Stream : Pipe) is
         Result : int;
      begin
         Result := pclose (Address (Stream));
         if Result = -1 then
            raise Program_Error with "pclose error";
         end if;
      end;
      function Get (Stream : Pipe) return Get_Result is
      begin
         return Get_Result (fgetc (Address (Stream)));
      end;
      function End_Of_File (Item : Get_Result) return Boolean is (Item = -1);
      function To_Ada (Item : Get_Result) return Character is (Character'Val (Get_Result'Pos (Item)));
   end;

   procedure Test is
      use Ada.Text_IO;
      use Pipes;
      P : Pipe;
      C : Get_Result;
   begin
      P := Open_Read ("cd .. & dir /b");
      loop
         C := Get (P);
         exit when End_Of_File (C);
         Put (To_Ada (C));
      end loop;
      Close (P);
   end;

begin
   Test;
end;

