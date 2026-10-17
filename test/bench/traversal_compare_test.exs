defmodule OrderedCollections.TraversalCompareTest do
  use ExUnit.Case, async: true

  @script Path.expand("../../bench/traversal_compare.sh", __DIR__)

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "ordered-traversal-test-#{System.os_time(:nanosecond)}-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)

    for directory <- ["lib", "bench", ".docs", "deps", "bin"] do
      File.mkdir_p!(Path.join(root, directory))
    end

    paths = ["mix.exs" | Enum.map(1..11, &"lib/source_#{&1}.ex")]
    for path <- paths, do: File.write!(Path.join(root, path), "original\n")

    git!(root, ["init", "--quiet"])
    git!(root, ["config", "core.hooksPath", "/dev/null"])
    git!(root, ["config", "commit.gpgsign", "false"])
    git!(root, ["add", "mix.exs", "lib"])

    git!(root, [
      "-c",
      "user.name=Traversal test",
      "-c",
      "user.email=test@example.invalid",
      "commit",
      "--quiet",
      "-m",
      "Baseline fixture"
    ])

    revision = root |> git!(["rev-parse", "HEAD"]) |> String.trim()
    File.write!(Path.join(root, "lib/source_1.ex"), "baseline\n")
    patch = git!(root, ["diff", "--", "lib/source_1.ex"])
    File.write!(Path.join(root, ".docs/traversal-baseline.patch"), patch)

    manifest =
      Enum.map_join(paths, "", fn path ->
        digest =
          :crypto.hash(:sha256, File.read!(Path.join(root, path))) |> Base.encode16(case: :lower)

        "#{digest}  #{path}\n"
      end)

    File.write!(Path.join(root, ".docs/traversal-baseline.sha256"), manifest)
    File.cp!(@script, Path.join(root, "bench/traversal_compare.sh"))
    File.write!(Path.join(root, "bench/traversal.exs"), "# Benchmark fixture\n")

    File.write!(Path.join(root, "bin/mix"), """
    #!/usr/bin/env bash
    set -euo pipefail
    printf '%s\\n' "$BENCH_LABEL" >> "$STUB_MIX_LOG"
    printf '{}\\n' > "$BENCH_OUTPUT"
    """)

    File.chmod!(Path.join(root, "bin/mix"), 0o755)
    {:ok, root: root, revision: revision, patch: patch}
  end

  test "missing baseline commit gives fetch guidance before invoking mix", %{root: root} do
    missing = String.duplicate("f", 40)
    {output, status} = run_comparison(root, missing)

    assert status != 0
    assert output =~ missing
    assert output =~ "git fetch"
    assert output =~ ~r/(baseline|commit|revision)/i
    refute File.exists?(Path.join(root, "mix-calls.log"))
  end

  test "a valid but altered patch is rejected by source checksums before invoking mix", context do
    altered = String.replace(context.patch, "+baseline\n", "+tampered\n")
    assert altered != context.patch
    File.write!(Path.join(context.root, ".docs/traversal-baseline.patch"), altered)
    {output, status} = run_comparison(context.root, context.revision)

    assert status != 0
    assert output =~ ~r/(checksum|sha256|integrity|manifest|verification|FAILED)/i
    refute File.exists?(Path.join(context.root, "mix-calls.log"))
  end

  test "a different baseline revision must still reconstruct the recorded source checksums",
       context do
    File.write!(Path.join(context.root, "lib/source_2.ex"), "different baseline source\n")
    git!(context.root, ["add", "lib/source_2.ex"])

    git!(context.root, [
      "-c",
      "user.name=Traversal test",
      "-c",
      "user.email=test@example.invalid",
      "commit",
      "--quiet",
      "-m",
      "Different baseline fixture"
    ])

    different_revision = context.root |> git!(["rev-parse", "HEAD"]) |> String.trim()

    assert File.read!(Path.join(context.root, ".docs/traversal-baseline.patch")) == context.patch
    {output, status} = run_comparison(context.root, different_revision)

    assert status != 0
    assert output =~ ~r/(checksum|sha256|integrity|manifest|verification|FAILED)/i
    refute File.exists?(Path.join(context.root, "mix-calls.log"))
  end

  test "an extra baseline source absent from the manifest is rejected before invoking mix",
       context do
    manifest_path = Path.join(context.root, ".docs/traversal-baseline.sha256")
    original_manifest = File.read!(manifest_path)
    File.write!(Path.join(context.root, "lib/extra.ex"), "unexpected compiled source\n")
    git!(context.root, ["add", "lib/extra.ex"])

    git!(context.root, [
      "-c",
      "user.name=Traversal test",
      "-c",
      "user.email=test@example.invalid",
      "commit",
      "--quiet",
      "-m",
      "Extra baseline source"
    ])

    revision_with_extra_source = context.root |> git!(["rev-parse", "HEAD"]) |> String.trim()
    assert File.read!(manifest_path) == original_manifest
    assert File.read!(Path.join(context.root, ".docs/traversal-baseline.patch")) == context.patch
    {output, status} = run_comparison(context.root, revision_with_extra_source)

    assert status != 0
    assert output =~ ~r/(inventory|manifest|unlisted|unexpected|source.*match)/i
    refute File.exists?(Path.join(context.root, "mix-calls.log"))
  end

  test "a valid revision, patch, and source manifest allow both benchmark runs", context do
    {output, status} = run_comparison(context.root, context.revision)

    assert status == 0, output
    assert File.read!(Path.join(context.root, "output/baseline/lib/source_1.ex")) == "baseline\n"

    assert File.read!(Path.join(context.root, "mix-calls.log")) ==
             "fixed-iterator-baseline\noptimized-working-tree\n"

    assert File.exists?(Path.join(context.root, "output/baseline.json"))
    assert File.exists?(Path.join(context.root, "output/current.json"))
  end

  defp run_comparison(root, revision) do
    System.cmd("bash", ["bench/traversal_compare.sh", Path.join(root, "output")],
      cd: root,
      stderr_to_stdout: true,
      env: [
        {"BASELINE_REVISION", revision},
        {"PATH", Path.join(root, "bin") <> ":" <> System.fetch_env!("PATH")},
        {"STUB_MIX_LOG", Path.join(root, "mix-calls.log")}
      ]
    )
  end

  defp git!(root, args) do
    {output, status} = System.cmd("git", ["-C", root | args], stderr_to_stdout: true)
    assert status == 0, output
    output
  end
end
