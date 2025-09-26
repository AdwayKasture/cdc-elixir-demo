defmodule CdcWal.ProductCommiter do
  alias CdcWal.Schema.Product
  alias CdcWal.Repo
  use GenServer


  @interval 10

  def start_link(_opts = []) do
    GenServer.start_link(__MODULE__,[],name: __MODULE__)
  end

  @impl true
  def init(_) do
    schedule_commit()
    Repo.insert!(Product.random_product())
    {:ok,:any}
  end


  @impl true
  def handle_info(:commit_to_db, _state) do
    perform_commit()
    schedule_commit()
    {:noreply,:any}
  end

  defp schedule_commit() do
    Process.send_after(self(),:commit_to_db,@interval)
  end

  defp perform_commit() do
    Repo.insert!(Product.random_product())
  end

  
end
