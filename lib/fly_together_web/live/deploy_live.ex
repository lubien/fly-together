defmodule FlyTogetherWeb.DeployLive do
  use FlyTogetherWeb, :live_view
  require Logger

  alias Fly.Client

  @impl true
  def mount(_params, session, socket) do
    socket =
      assign(socket,
        app_id: nil,
        organizations: [],
        token: nil,
        password: nil,
        release_id: nil,

        state: :loading,
        app: nil,
        count: 0,
        authenticated: true
      )

    # Only make the API call if the websocket is setup. Not on initial render.
    # if connected?(socket) do
    #   {:ok, fetch_app(socket)}
    # else
    #   {:ok, socket}
    # end
    {:ok, socket}
  end

  defp client_config(socket) do
    Fly.Client.config(access_token: socket.assigns.token)
  end

  defp fetch_app(socket) do
    app_name = socket.assigns.app_name

    Process.send_after(self(), "refetch_app", 3_000)

    case Client.fetch_app(app_name, socket.assigns.config) do
      {:ok, app} ->
        assign(socket, :app, app)

      {:error, :unauthorized} ->
        put_flash(socket, :error, "Not authenticated")

      {:error, reason} ->
        Logger.error("Failed to load app '#{inspect(app_name)}'. Reason: #{inspect(reason)}")

        put_flash(socket, :error, reason)
    end
  end

  @impl true
  def handle_event("setup_auth", %{"auth" => %{"token" => token}}, socket) do
    {:noreply,
      socket
      |> assign(token: token)
      |> fetch_organizations()
    }
  end

  @impl true
  def handle_event("deploy", %{"deploy" => %{"organization_id" => organization_id}}, socket) do
    {:noreply,
      socket
      |> create_app(organization_id)
      |> set_app_password()
      |> deploy_image()
    }
  end

  def handle_event("click", _params, socket) do
    {:noreply, assign(socket, count: socket.assigns.count + 1)}
  end

  @impl true
  def handle_info("refetch_app", socket) do
    {:noreply, fetch_app(socket)}
  end

  defp fetch_organizations(socket) do
    case Client.fetch_organizations(%{}, client_config(socket)) do
      {:ok, %{"organizations" => %{"nodes" => organizations}}} ->
        assign(socket, :organizations, organizations)

      {:error, :unauthorized} ->
        put_flash(socket, :error, "Not authenticated")

      {:error, reason} ->
        # Logger.error("Failed to load app '#{inspect(app_name)}'. Reason: #{inspect(reason)}")

        put_flash(socket, :error, reason)
    end
  end

  defp create_app(socket, organization_id) do
    args = %{"organizationId" => organization_id}
    case Client.create_app(args, client_config(socket)) do
      {:ok, app_id} ->
        assign(socket, :app_id, app_id)

      {:error, :unauthorized} ->
        put_flash(socket, :error, "Not authenticated")

      {:error, reason} ->
        # Logger.error("Failed to load app '#{inspect(app_name)}'. Reason: #{inspect(reason)}")

        put_flash(socket, :error, reason)
    end
  end

  defp set_app_password(%{assigns: %{app_id: nil}} = socket) do
    socket
  end

  defp set_app_password(%{assigns: %{app_id: app_id}} = socket) do
    password = for _ <- 1..12, into: "", do: <<Enum.random('0123456789abcdef')>>
    args = %{
      "appId" => app_id,
      "secrets" => [
        %{
          "key" => "LIVEBOOK_PASSWORD",
          "value" => password
        }
      ]
    }

    case Client.set_secrets(args, client_config(socket)) do
      {:ok, _app_id} ->
        assign(socket, :password, password)

      {:error, :unauthorized} ->
        put_flash(socket, :error, "Not authenticated")

      {:error, reason} ->
        # Logger.error("Failed to load app '#{inspect(app_name)}'. Reason: #{inspect(reason)}")

        put_flash(socket, :error, reason)
    end
  end

  defp deploy_image(%{assigns: %{app_id: nil}} = socket) do
    socket
  end

  defp deploy_image(%{assigns: %{app_id: app_id}} = socket) do
    args = %{
      "appId" => app_id,
      "strategy" => "IMMEDIATE",
      "image" => "registry-1.docker.io/livebook/livebook:latest",
      "definition" => %{
        "kill_timeout" => 5,
        "kill_signal" => "SIGINT",
        "processes" => [],
        "experimental" => %{
          "allowed_public_ports" => [],
          "auto_rollback" => true
        },
        "services" => [
          %{
            "processes" => [
              "app"
            ],
            "protocol" => "tcp",
            "internal_port" => 8080,
            "concurrency" => %{
              "soft_limit" => 20,
              "hard_limit" => 25,
              "type" => "connections"
            },
            "ports" => [
              %{
                "port" => 80,
                "handlers" => [
                  "http"
                ]
              },
              %{
                "port" => 443,
                "handlers" => [
                  "tls",
                  "http"
                ]
              }
            ],
            "tcp_checks" => [
              %{
                "interval" => "15s",
                "timeout" => "2s",
                "grace_period" => "1s",
                "restart_limit" => 6
              }
            ],
            "http_checks" => [],
            "script_checks" => []
          }
        ],
        "env" => %{}
      }
    }

    config = client_config(socket)
    |> Keyword.put(:connection_opts, [recv_timeout: 120_000])

    case Client.deploy_image(args, config) do
      {:ok, release_id} ->
        socket
        |> assign(:release_id, release_id)
        |> put_flash(:info, "App deployed with id #{release_id}")

      {:error, :unauthorized} ->
        put_flash(socket, :error, "Not authenticated")

      {:error, reason} ->
        # Logger.error("Failed to load app '#{inspect(app_name)}'. Reason: #{inspect(reason)}")

        put_flash(socket, :error, reason)
    end
  end

  def organizations_to_select(organizations) do
    for org <- organizations do
      [value: org["id"], key: org["name"]]
    end
  end

  def app_link(name, token) do
    "https://#{name}.fly.dev?token=#{token}"
  end
end
