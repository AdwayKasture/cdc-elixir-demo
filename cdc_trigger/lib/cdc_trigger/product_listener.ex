defmodule CdcTrigger.ProductListener do
  use GenServer

  @channel "product_cdc_channel"

  def start_link(opts) do
    GenServer.start_link(__MODULE__,opts,name: __MODULE__)
  end

  @impl GenServer 
  def init(opts) do
    {:ok,pid} = Postgrex.Notifications.start_link(opts)
    {:ok,ref} = Postgrex.Notifications.listen(pid,@channel)
    {:ok,{pid,ref}}
  end

  @impl GenServer
  def handle_info({:notification,pid,ref,@channel,message}, {pid,ref}) do
    message
    |> JSON.decode!()
    |> parse()
    {:noreply,{pid,ref}}
  end

  def parse(%{"action" => "I"} = insert_rec) do
    %{"id" => id,"name" => name,"price" => price} = insert_rec["new"]
    IO.puts("Inserting #{id},#{name},#{price} for #{insert_rec["table"]} ")
  end

  def parse(%{"action" => "D"} = delete_rec) do
    %{"id" => id,"name" => name,"price" => price} = delete_rec["old"]
    IO.puts("Deleting #{id},#{name},#{price} for #{delete_rec["table"]} ")
  end

  def parse(%{"action" => "U"} = update_rec) do
    %{"id" => old_id,"name" => old_name,"price" => old_price} = update_rec["old"]
    %{"id" => new_id,"name" => new_name,"price" => new_price} = update_rec["new"]
    IO.puts(
      "Updated #{old_id},#{old_name},#{old_price} to #{new_id},#{new_name},#{new_price} for #{update_rec["table"]}"
    )
  end

end
