# SafeC End-to-End CLI Tutorial

This is a small host-local walkthrough for testing the current `safec`
compiler end to end after it has already been built.

It is intentionally practical rather than portable:

- it assumes you are running from this repository checkout
- it assumes the Ada toolchain is available through Alire on this host
- it relies on the same macOS linker `syslibroot` pattern used by `compiler_impl/safec.gpr`

The flow below does four things:

1. writes a small Safe program
2. checks it with `safec check`
3. emits JSON plus Ada/SPARK with `safec emit --ada-out-dir`
4. compiles and runs a tiny Ada driver against the emitted package

It also includes an optional macOS-only Jorvik smoke step that exercises the
local linker fix used for native binaries that depend on `gnat.adc`.

## 1. Start From the Repo Root

```bash
cd /Users/agentc1/src/github.com/agentc1/safe
```

The compiler binary should already exist at:

```bash
compiler_impl/bin/safec
```

If you need to rebuild it first:

```bash
cd compiler_impl
$HOME/bin/alr build
cd ..
```

## 2. Create a Temporary Work Area

```bash
BASE_TMP="${TMPDIR%/}"
[ -d "$BASE_TMP" ] || BASE_TMP=/tmp
WORK="$(mktemp -d "$BASE_TMP"/safec-e2e.XXXXXX)"
mkdir -p "$WORK/out" "$WORK/iface" "$WORK/ada"
```

## 3. Write an Interesting Safe Sample

This sample uses two functions:

- `Signum`, which returns `-1`, `0`, or `1`
- `Bounded_Add`, which adds two small values and returns a wider bounded result

Save it as `"$WORK/safe_return.safe"`:

```bash
cat > "$WORK/safe_return.safe" <<'EOF'
package Safe_Return is

   type Bounded is range -500 .. 500;
   type Small is range -10 .. 10;

   function Signum (V : Bounded) return Small is
   begin
      if V > 0 then
         return 1;
      elsif V < 0 then
         return -1;
      else
         return 0;
      end if;
   end Signum;

   function Bounded_Add (A, B : Small) return Bounded is
   begin
      return Bounded (A) + Bounded (B);
   end Bounded_Add;

end Safe_Return;
EOF
```

## 4. Run the Compiler Frontend

First run the normal frontend check:

```bash
compiler_impl/bin/safec check "$WORK/safe_return.safe"
```

Then emit all artifacts, including Ada/SPARK:

```bash
compiler_impl/bin/safec emit \
  "$WORK/safe_return.safe" \
  --out-dir "$WORK/out" \
  --interface-dir "$WORK/iface" \
  --ada-out-dir "$WORK/ada"
```

You should now have:

```text
$WORK/out/safe_return.ast.json
$WORK/out/safe_return.typed.json
$WORK/out/safe_return.mir.json
$WORK/iface/safe_return.safei.json
$WORK/ada/safe_return.ads
$WORK/ada/safe_return.adb
$WORK/ada/safe_runtime.ads
```

You can also validate the emitted MIR directly:

```bash
compiler_impl/bin/safec validate-mir "$WORK/out/safe_return.mir.json"
compiler_impl/bin/safec analyze-mir "$WORK/out/safe_return.mir.json"
```

## 5. Write a Tiny Ada Driver

The emitted Safe package is a normal Ada package, so the easiest way to execute
it is to compile a small Ada `main.adb` that calls into it.

Save this as `"$WORK/main.adb"`:

```bash
cat > "$WORK/main.adb" <<'EOF'
with Ada.Text_IO; use Ada.Text_IO;
with Safe_Return;
use type Safe_Return.Small;
use type Safe_Return.Bounded;

procedure Main is
   S1 : Safe_Return.Small;
   S2 : Safe_Return.Bounded;
begin
   S1 := Safe_Return.Signum (-42);
   S2 := Safe_Return.Bounded_Add (-3, 7);

   Put_Line ("Signum(-42) =" & Integer'Image (Integer (S1)));
   Put_Line ("Bounded_Add(-3, 7) =" & Integer'Image (Integer (S2)));
end Main;
EOF
```

Create a minimal project file:

```bash
cat > "$WORK/build.gpr" <<'EOF'
project Build is
   Sdk_Root := External ("SDKROOT", "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk");
   for Source_Dirs use (".", "ada");
   for Object_Dir use "obj";

   package Linker is
      for Default_Switches ("Ada") use ("-Wl,-syslibroot," & Sdk_Root);
   end Linker;
end Build;
EOF
```

## 6. Compile and Run the Emitted Ada

On this macOS host, the generated project file carries the linker sysroot fix.
Export `SDKROOT` so the project can point at the active CLT/Xcode SDK.

```bash
export SDKROOT="$(xcrun --show-sdk-path)"

cd compiler_impl
$HOME/bin/alr exec -- gprbuild -P "$WORK/build.gpr" main.adb
cd ..
```

The executable is written to:

```text
$WORK/obj/main
```

Run it:

```bash
"$WORK/obj/main"
```

Expected output:

```text
Signum(-42) =-1
Bounded_Add(-3, 7) = 4
```

## 7. Optional: Exercise the Local Jorvik Link Path

This repository now generates macOS-aware Ada project files that carry the same
linker `syslibroot` fix used by `compiler_impl/safec.gpr`. The command below is
not required for normal sequential emitted-Ada testing, but it is a good
host-local proof that Jorvik-dependent native links now work on this machine.

Create a tiny Ada program plus `gnat.adc`:

```bash
mkdir -p "$WORK/jorvik"

cat > "$WORK/jorvik/hello_jorvik.adb" <<'EOF'
with Ada.Text_IO; use Ada.Text_IO;

procedure Hello_Jorvik is
begin
   Put_Line ("Jorvik link path OK");
end Hello_Jorvik;
EOF

cat > "$WORK/jorvik/gnat.adc" <<'EOF'
pragma Partition_Elaboration_Policy(Sequential);
pragma Profile(Jorvik);
EOF

cat > "$WORK/jorvik/build.gpr" <<'EOF'
project Build is
   Sdk_Root := External ("SDKROOT", "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk");
   for Source_Dirs use (".");
   for Object_Dir use "obj";

   package Compiler is
      for Default_Switches ("Ada") use ("-gnatec=gnat.adc");
   end Compiler;

   package Linker is
      for Default_Switches ("Ada") use ("-Wl,-syslibroot," & Sdk_Root);
   end Linker;
end Build;
EOF
```

Build and run it:

```bash
export SDKROOT="$(xcrun --show-sdk-path)"

cd compiler_impl
$HOME/bin/alr exec -- gprbuild -P "$WORK/jorvik/build.gpr" hello_jorvik.adb
cd ..

"$WORK/jorvik/obj/hello_jorvik"
```

Expected output:

```text
Jorvik link path OK
```

If you remove the `package Linker` stanza from that project on this exact host
and toolchain, the link is expected to fail with `ld: library not found for
-lSystem`. That is the failure mode the generated macOS-aware project fixes.

## 8. What This Proves

If all of the steps above pass, you have exercised the current compiler stack
end to end on this host:

- Safe source parsing and semantic checking
- MIR emission and validation
- `safei-v1` interface emission
- PR09 Ada/SPARK emission
- host-local Ada compilation of the emitted package
- execution of a native binary linked against the emitted code
- host-local Jorvik-configured native linking with `gnat.adc`

## Notes

- This is a host-local smoke path, not a replacement for the repo gates.
- The PR09 CI gates are intentionally compile-only; the explicit native link and
  execution step here goes beyond what CI currently enforces.
- The Jorvik step above is macOS-specific and depends on the local Alire GNAT
  toolchain plus the linker `syslibroot` project stanza.
- If you want a minimal emission-only sample instead, use
  `tests/positive/emitter_surface_proc.safe`.
