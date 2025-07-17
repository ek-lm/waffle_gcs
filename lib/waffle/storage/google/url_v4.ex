defmodule Waffle.Storage.Google.UrlV4 do
  @moduledoc """
  This is an implementation of the v4 URL signing for Google Cloud Storage. See
  [the gcs_signed_url documentation](https://hexdocs.pm/gcs_signed_url/readme.html)
  for more details.
  """

  use Waffle.Storage.Google.Url

  alias Waffle.Types
  alias Waffle.Storage.Google.{CloudStorage, Util}

  defdelegate expiry(opts \\ []), to: Waffle.Storage.Google.UrlV2
  defdelegate signed?(opts \\ []), to: Waffle.Storage.Google.UrlV2
  defdelegate endpoint(opts \\ []), to: Waffle.Storage.Google.UrlV2

  # Default expiration time is 3600 seconds, or 1 hour
  @default_expiry 3600

  # The official Google Cloud Storage host
  @endpoint "storage.googleapis.com"

  @impl Waffle.Storage.Google.Url
  def build(definition, version, meta, options) do
    path = CloudStorage.path_for(definition, version, meta)

    if signed?(options) do
      build_signed_url(definition, path, options)
    else
      build_url(definition, path)
    end
  end

  @spec build_url(Types.definition(), String.t()) :: String.t()
  defp build_url(definition, path) do
    %URI{
      host: endpoint(),
      path: build_path(definition, path),
      scheme: "https"
    }
    |> URI.to_string()
  end

  @spec build_signed_url(Types.definition(), String.t(), Keyword.t()) :: String.t()
  defp build_signed_url(definition, path, options) do
    oauth_config = %GcsSignedUrl.SignBlob.OAuthConfig{
      service_account: get_service_account(),
      access_token: get_token()
    }

    opts = [expires: @default_expiry] |> Keyword.merge(options)
    GcsSignedUrl.generate_v4(oauth_config, CloudStorage.bucket(definition), path, opts)
  end

  @spec build_path(Types.definition(), String.t()) :: String.t()
  defp build_path(definition, path) do
    path =
      if endpoint() != @endpoint do
        path
      else
        bucket_and_path(definition, path)
      end

    path
    |> Util.prepend_slash()
    |> URI.encode()
  end

  @spec bucket_and_path(Types.definition(), String.t()) :: String.t()
  defp bucket_and_path(definition, path) do
    definition
    |> CloudStorage.bucket()
    |> Path.join(path)
  end

  defp get_token() do
    token_store = Application.fetch_env!(:waffle, :token_fetcher)

    token_store.get_token()
  end

  defp get_service_account() do
    Application.fetch_env!(:waffle, :service_account)
  end
end
