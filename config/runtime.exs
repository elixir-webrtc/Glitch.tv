import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/glitch start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :glitch, GlitchWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /etc/glitch/glitch.db
      """

  config :glitch, Glitch.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :glitch, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :glitch, GlitchWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  streamer_username =
    System.get_env("GLITCH_STREAMER_USERNAME") ||
      raise "Environment variable GLITCH_STREAMER_USERNAME is missing."

  streamer_password =
    System.get_env("GLITCH_STREAMER_PASSWORD") ||
      raise "Environment variable GLITCH_STREAMER_PASSWORD is missing."

  enable_recordings =
    case(System.get_env("GLITCH_ENABLE_RECORDINGS")) do
      "true" -> true
      _ -> false
    end

  enable_share_button =
    case(System.get_env("GLITCH_ENABLE_SHARE_BUTTON")) do
      "true" -> true
      _ -> false
    end

  enable_elixirconf_links =
    case(System.get_env("GLITCH_ENABLE_ELIXIRCONF_LINKS")) do
      "true" -> true
      _ -> false
    end

  elixirconf_day =
    case(System.get_env("GLITCH_ELIXIRCONF_DAY")) do
      nil ->
        "day1"

      day ->
        day
    end

  slow_mode_delay_s =
    case System.get_env("GLITCH_SLOW_MODE_DELAY_S") do
      nil ->
        1

      seconds ->
        case Integer.parse(String.trim(seconds)) do
          {num, _} -> num
          :error -> 1
        end
    end

  turn_servers =
    case System.get_env("GLITCH_TURN_SERVERS") do
      nil ->
        nil

      servers ->
        # check JSON validity
        JSON.decode!(servers)
        servers
    end

  config :glitch,
    streamer_username: streamer_username,
    streamer_password: streamer_password,
    enable_recordings: enable_recordings,
    enable_share_button: enable_share_button,
    enable_elixirconf_links: enable_elixirconf_links,
    elixirconf_day: elixirconf_day,
    slow_mode_delay_s: slow_mode_delay_s,
    turn_servers: turn_servers

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :glitch, GlitchWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :glitch, GlitchWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
