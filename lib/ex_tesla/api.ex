defmodule ExTesla.Api do
  @moduledoc false
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://owner-api.teslamotors.com/")

  plug(Tesla.Middleware.Headers, [
    {"User-Agent",
     "Mozilla/5.0 (Linux; Android 9.0.0; VS985 4G Build/LRX21Y; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/58.0.3029.83 Mobile Safari/537.36"}
  ])

  plug(Tesla.Middleware.JSON)

  defp login_with_oauth(oauth) do
    url = "/oauth/token"

    data = %{
      grant_type: "password",
      client_id: oauth["v1"]["id"],
      client_secret: oauth["v1"]["secret"],
      email: Application.get_env(:ex_tesla, :email),
      password: Application.get_env(:ex_tesla, :password)
    }

    result = post(url, data)

    case result do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, result} -> {:error, "Got status #{result.status}"}
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Get a token required for Tesla's API.
  """
  def get_token do
    with {:ok, oauth} <- ExTesla.Oauth.get_oauth(),
         {:ok, result} <- login_with_oauth(oauth) do
      {:ok, result}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Check token is still valid and renew if required.
  """
  def check_token(nil), do: get_token()

  def check_token(token) do
    now = :os.system_time(:seconds)
    expires = token["created_at"] + token["expires_in"] - 86400

    cond do
      now > expires ->
        get_token()

      true ->
        {:ok, token}
    end
  end

  @doc """
  Get a HTTP client for the token.
  """
  def client(token) do
    Tesla.client([
      {Tesla.Middleware.Headers, [{"authorization", "Bearer " <> token["access_token"]}]}
    ])
  end

  defp process_response(result) do
    case result do
      {:ok, %{status: 200, body: %{"response" => response}}} -> {:ok, response}
      {:ok, %{status: 200, body: response}} -> {:ok, response}
      {:ok, %{status: 200}} -> {:error, "Got no body in response"}
      {:ok, result} -> {:error, "Got error status #{result.status}"}
      err -> err
    end
  end

  @doc """
  Get a list of all vehicles belonging to this account.
  """
  def list_all_vehicles(%Tesla.Client{} = client) do
    url = "/api/1/vehicles"
    get(client, url) |> process_response
  end

  @doc """
  Get all data for a vehicle.
  """
  def get_vehicle_data(%Tesla.Client{} = client, vehicle) do
    vehicle_id = vehicle["id"]
    url = "/api/1/vehicles/#{vehicle_id}/data"
    get(client, url) |> process_response
  end

  @doc """
  Get the vehicle state for a vehicle.
  """
  def get_vehicle_state(%Tesla.Client{} = client, vehicle) do
    vehicle_id = vehicle["id"]
    url = "/api/1/vehicles/#{vehicle_id}/data_request/vehicle_state"
    get(client, url) |> process_response
  end

  @doc """
  Get the charge state for a vehicle.
  """
  def get_charge_state(%Tesla.Client{} = client, vehicle) do
    vehicle_id = vehicle["id"]
    url = "/api/1/vehicles/#{vehicle_id}/data_request/charge_state"
    get(client, url) |> process_response
  end

  @doc """
  Get the climate state for a vehicle.
  """
  def get_climate_state(%Tesla.Client{} = client, vehicle) do
    vehicle_id = vehicle["id"]
    url = "/api/1/vehicles/#{vehicle_id}/data_request/climate_state"
    get(client, url) |> process_response
  end

  @doc """
  Get the drive state for a vehicle.
  """
  def get_drive_state(%Tesla.Client{} = client, vehicle) do
    vehicle_id = vehicle["id"]
    url = "/api/1/vehicles/#{vehicle_id}/data_request/drive_state"
    get(client, url) |> process_response
  end

  @doc """
  Returns a list of nearby Tesla-operated charging stations. (Requires car software version 2018.48 or higher.)
  """
  def nearby_charging_sites(%Tesla.Client{} = client, vehicle) do
    vehicle_id = vehicle["id"]
    url = "/api/1/vehicles/#{vehicle_id}/nearby_charging_sites"
    get(client, url) |> process_response
  end

  @doc """
  Wakes up the vehicle from a sleeping state.
  """
  def wake_up(%Tesla.Client{} = client, vehicle) do
    vehicle_id = vehicle["id"]
    url = "/api/1/vehicles/#{vehicle_id}/wake_up"
    post(client, url, %{}) |> process_response
  end

  # Alerts

  @doc """
  Honks the horn twice.
  """
  def honk_horn(%Tesla.Client{} = client, vehicle) do
    vehicle_id = vehicle["id"]
    url = "/api/1/vehicles/#{vehicle_id}/command/honk_horn"
    post(client, url, %{}) |> process_response
  end

  @doc """
  Flashes the headlishes once.
  """
  def flash_lights(%Tesla.Client{} = client, vehicle) do
    vehicle_id = vehicle["id"]
    url = "/api/1/vehicles/#{vehicle_id}/command/flash_lights"
    post(client, url, %{}) |> process_response
  end

  # Door Locks

  @doc """
  Unlocks the doors to the car. Extends the handles on the S and X.
  """
  def unlock_doors(%Tesla.Client{} = client, vehicle) do
    vehicle_id = vehicle["id"]
    url = "/api/1/vehicles/#{vehicle_id}/command/door_unlock"
    post(client, url, %P{}) |> process_response
  end

  @doc """
  Locks the doors to the car. Retracts the handles on the S and X, if they are extended.
  """
  def lock_doors(%Tesla.Client{} = client, vehicle) do
    vehicle_id = vehicle["id"]
    url = "/api/1/vehicles/#{vehicle_id}/command/door_lock"
    post(client, url, %P{}) |> process_response
  end
end
