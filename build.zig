const std = @import("std");

pub fn build(b: *std.build.Builder) void {
  const lib = b.addSharedLibrary("life", "life.zig", b.version(0, 0, 0));
  lib.setBuildMode(.ReleaseSmall);
  lib.setTarget(.{.cpu_arch = .wasm32, .os_tag = .freestanding});
  lib.setOutputDir("./");
  b.default_step.dependOn(&lib.step);
}
