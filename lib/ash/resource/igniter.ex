defmodule Ash.Resource.Igniter do
  @moduledoc "Codemods for working with Ash.Resource modules"

  @doc "List all resource modules found in the project"
  def list_resources(igniter) do
    Igniter.Code.Module.find_all_matching_modules(igniter, fn _mod, zipper ->
      zipper
      |> Igniter.Code.Module.move_to_use(resource_mods())
      |> case do
        {:ok, _} ->
          true

        _ ->
          false
      end
    end)
  end

  @doc "Gets the domain from the given resource module"
  @spec domain(Igniter.t(), Ash.Resource.t()) ::
          {:ok, Igniter.t(), Ash.Domain.t()} | {:error, Igniter.t()}
  def domain(igniter, resource) do
    case Igniter.Code.Module.find_module(igniter, resource) do
      {:ok, {igniter, _source, zipper}} ->
        with {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper),
             {:ok, zipper} <-
               Igniter.Code.Module.move_to_use(zipper, resource_mods()),
             {:ok, zipper} <-
               Igniter.Code.Function.move_to_nth_argument(zipper, 1),
             {:ok, zipper} <- Igniter.Code.Keyword.get_key(zipper, :domain),
             module when not is_nil(module) <-
               Igniter.Code.Module.to_module_name(zipper.node) do
          {:ok, igniter, module}
        else
          _ ->
            {:error, igniter}
        end

      {:error, igniter} ->
        {:error, igniter}
    end
  end

  def resource_mods do
    app_name = Igniter.Project.Application.app_name()

    [Ash.Resource | List.wrap(Application.get_env(app_name, :base_resources))]
  end

  @doc "Adds the given code block to the resource's `attributes` block"
  def add_attribute(igniter, resource, attribute) do
    Igniter.Code.Module.find_and_update_module!(igniter, resource, fn zipper ->
      with {:ok, zipper} <-
             Igniter.Code.Function.move_to_function_call_in_current_scope(
               zipper,
               :attributes,
               1
             ),
           {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
        {:ok, Igniter.Code.Common.add_code(zipper, attribute)}
      else
        _ ->
          attributes_with_attribute = """
          attributes do
            #{attribute}
          end
          """

          {:ok, Igniter.Code.Common.add_code(zipper, attributes_with_attribute)}
      end
    end)
  end

  @doc "Adds the given code block to the resource's `actions` block"
  def add_action(igniter, resource, action) do
    Igniter.Code.Module.find_and_update_module!(igniter, resource, fn zipper ->
      with {:ok, zipper} <-
             Igniter.Code.Function.move_to_function_call_in_current_scope(zipper, :actions, 1),
           {:ok, zipper} <- Igniter.Code.Common.move_to_do_block(zipper) do
        {:ok, Igniter.Code.Common.add_code(zipper, action)}
      else
        _ ->
          actions_with_action = """
          actions do
            #{action}
          end
          """

          {:ok, Igniter.Code.Common.add_code(zipper, actions_with_action)}
      end
    end)
  end
end
