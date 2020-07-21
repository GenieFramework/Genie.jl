using Genie, MbedTLS

function configure_dev_ssl()
  cert = Genie.Assets.embedded_path(joinpath("files", "ssl", "localhost.crt")) |> MbedTLS.crt_parse_file
  key = Genie.Assets.embedded_path(joinpath("files", "ssl", "localhost.key")) |> MbedTLS.parse_keyfile

  ssl_config = MbedTLS.SSLConfig(true)
  entropy = MbedTLS.Entropy()
  rng = MbedTLS.CtrDrbg()
  MbedTLS.config_defaults!(ssl_config, endpoint=MbedTLS.MBEDTLS_SSL_IS_SERVER)

  MbedTLS.authmode!(ssl_config, MbedTLS.MBEDTLS_SSL_VERIFY_NONE)
  MbedTLS.seed!(rng, entropy)
  MbedTLS.rng!(ssl_config, rng)
  MbedTLS.own_cert!(ssl_config, cert, key)
  MbedTLS.ca_chain!(ssl_config)

  Genie.config.ssl_config = ssl_config

  nothing
end

Genie.Configuration.isdev() && Genie.config.ssl_enabled && configure_dev_ssl()