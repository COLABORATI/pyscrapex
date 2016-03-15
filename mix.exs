defmodule Downloader.Mixfile do
  use Mix.Project

  def project do
    [app: :downloader, version: "0.0.1", deps: deps,
     elixir: ">= 1.2.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod]
  end

  def application do
    [applications: [:logger, :httpoison, :poolboy],
     mod: {Downloader, []}]
  end

  defp deps do
    [{:erlport, git: "https://github.com/hdima/erlport.git"},
     {:poolboy,   "~> 1.5"},
     {:httpoison, "~> 0.8.0"},
     {:poison,    "> 0.8.0"},
     {:pattern_tap, git: "https://github.com/mgwidmann/elixir-pattern_tap"}
    ]
  end
end

# Type `mix help deps` for more examples and options, example:
#   {:mydep, "~> 0.3.0"}
#   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
# {:pattern_tap, git: "https://github.com/mgwidmann/elixir-pattern_tap.git"},
# {:floki, "> 0.7"}
